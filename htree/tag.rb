require 'htree/raw_string'
require 'htree/text'
require 'htree/scan' # for Pat::Name

module HTree
  class Name
=begin
element name                    prefix  uri     localname
-{u}n, n with xmlns=u           false   u       n
p{u}n, p:n with xmlns:p=u       p       u       n
{u}n                            nil     u       n
n with xmlns=''                 nil     nil     n

attribute name
xmlns=                          xmlns   nil     nil
xmlns:n=                        xmlns   nil     n
p{u}n=, p:n= with xmlns:p=u     p       u       n
{u}n=                           nil     u       n
n=                              nil     nil     n
=end
    def Name.parse_element_name(name, namespaces)
      if /\{(.*)\}/ =~ name
        # In to_xml, 
        # "-{u}n" means "use default namespace",
        # "p{u}n" means "use the specified prefix p" and
        # "{u}n" means "allocate some namespace prefix"
        case $`
        when '-'; Name.new(false, $1, $')
        when ''; Name.new(nil, $1, $')
        else Name.new($`, $1, $')
        end
      elsif /:/ =~ name && namespaces.include?($`)
        Name.new($`, namespaces[$`], $')
      elsif namespaces.include?(nil)
        Name.new(false, namespaces[nil], name)
      else
        Name.new(nil, nil, name)
      end
    end

    def Name.parse_attribute_name(name, namespaces)
      if name == 'xmlns'
        Name.new('xmlns', nil, nil)
      elsif /\Axmlns:/ =~ name
        Name.new('xmlns', nil, $')
      elsif /\{(.*)\}/ =~ name
        case $`
        when ''; Name.new(nil, $1, $')
        else Name.new($`, $1, $')
        end
      elsif /:/ =~ name && namespaces.include?($`)
        Name.new($`, namespaces[$`], $')
      else
        Name.new(nil, nil, name)
      end
    end

    def initialize(namespace_prefix, namespace_uri, local_name)
      @namespace_prefix = namespace_prefix && namespace_prefix.dup
      @namespace_uri = namespace_uri && namespace_uri.dup
      @local_name = local_name && local_name.dup
      if @namespace_prefix && /\A#{Pat::Name}\z/ !~ @namespace_prefix
        raise STag::Error, "invalid namespace prefix: #{@namespace_prefix.inspect}"
      end
      if @local_name && /\A#{Pat::Name}\z/ !~ @local_name
        raise STag::Error, "invalid local name: #{@local_name.inspect}"
      end
    end
    attr_reader :namespace_prefix, :namespace_uri, :local_name

    def xmlns?
      @namespace_prefix == 'xmlns' && @namespace_uri == nil
    end

    def universal_name
      if @namespace_uri
        "{#{@namespace_uri}}#{@local_name}"
      else
        @local_name.dup
      end
    end

    def qualified_name
      if @namespace_uri
        case @namespace_prefix
        when nil # namespace is not determined yet.
          nil
        when false # default namespace
          @local_name.dup
        else
          "#{@namespace_prefix}:#{@local_name}"
        end
      elsif @local_name
        @local_name.dup
      else
        "xmlns"
      end
    end
  end

  class STag < Markup
    def initialize(name, attributes=[], inherited_namespaces={})
      init_raw_string
      # normalize xml declaration name and attribute value.
      attributes = attributes.map {|aname, val|
        if !(Name === aname) && /\A#{Pat::Name}?(?:\{.*\})?#{Pat::Name}\z/ !~ aname
          raise STag::Error, "invalid attribute name: #{aname.inspect}"
        end
        if !(Name === aname) && /\Axmlns(?:\z|:)/ =~ aname
          aname = Name.parse_attribute_name(aname, nil)
        end
        val = Text.new(val) unless Text === val
        [aname, val]
      }

      @inherited_namespaces = inherited_namespaces
      @xmlns_decls = {}
      attributes.each {|aname, text|
        next unless Name === aname
        next unless aname.xmlns?
        if aname.local_name
          @xmlns_decls[aname.local_name] = text.to_s
        else
          uri = text.to_s
          @xmlns_decls[nil] = uri.empty? ? nil : uri
        end
      }
      @namespaces = make_namespaces

      @name = Name.parse_element_name(name, @namespaces) unless Name === name

      @attributes = attributes.map {|aname, text|
        aname = Name.parse_attribute_name(aname, @namespaces) unless Name === aname
        [aname, text]
      }
    end
    attr_reader :name, :attributes, :inherited_namespaces, :namespaces

    def namespace_prefix() @name.namespace_prefix end
    def namespace_uri() @name.namespace_uri end
    def local_name() @name.local_name end
    def universal_name() @name.universal_name end
    def qualified_name() @name.qualified_name end

    def make_namespaces(inherited_namespaces=@inherited_namespaces)
      namespaces = inherited_namespaces.dup
      @xmlns_decls.each {|prefix, uri|
        if prefix
          namespaces[prefix] = uri
        elsif uri
          namespaces[nil] = uri
        else
          namespaces.delete nil
        end
      }
      namespaces
    end

    def each_namespace_attribute
      @xmlns_decls.each {|name, uri|
        yield name, uri
      }
    end

    def each_attribute_info
      @attributes.each {|name, text|
        next if name.xmlns?
        yield name, text
      }
    end

    def each_attribute_text
      each_attribute_info {|name, text|
        yield name.universal_name, text
      }
    end

    def fetch_attribute_text(universal_name, *rest)
      each_attribute_text {|uname, text|
        return text if universal_name == uname
      }
      if block_given?
        yield
      elsif !rest.empty?
        rest[0]
      else
        raise IndexError, "attribute not found: #{universal_name.inspect}"
      end
    end

    def get_attribute_text(universal_name)
      fetch_attribute_rcdata(universal_name, nil)
    end

    #def prepare_xmlns(inherited_namespaces)
    #end

    def to_xml
      result = "<#{@name.qualified_name || @name.universal_name}"
      @attributes.each {|aname, text|
        result << " #{aname.qualified_name}=#{text.to_xml_attvalue}"
      }
      result << '>'
    end

    def to_emptytag_xml
      result = "<#{@name.qualified_name || @name.universal_name}"
      @attributes.each {|aname, text|
        result << " #{aname.qualified_name}=#{text.to_xml_attvalue}"
      }
      result << ' />'
    end

    def to_etag_xml
      "</#{@name.qualified_name || @name.universal_name}>"
    end

  end

  class ETag < Markup
    def initialize(qualified_name)
      init_raw_string
      @qualified_name = qualified_name
    end
    attr_reader :qualified_name

    def to_xml
      "</#{@qualified_name}>"
    end
  end

  class BogusETag < ETag
    def to_xml
      ""
    end
  end

end
