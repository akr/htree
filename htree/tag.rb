require 'htree/raw_string'
require 'htree/text'
require 'htree/scan' # for Pat::Name

module HTree
  class Name
=begin
element name                    prefix  uri     localname
{u}n, n with xmlns=u            nil     u       n
p{u}n, p:n with xmlns:p=u       p       u       n
n with xmlns=''                 nil     nil     n

attribute name
xmlns=                          xmlns   nil     nil
xmlns:n=                        xmlns   nil     n
p{u}n=, p:n= with xmlns:p=u     p       u       n
n=                              nil     nil     n
=end
    def Name.parse_element_name(name, namespaces)
      if /\{(.*)\}/ =~ name
        # In to_xml, 
        # "{u}n" means "use default namespace",
        # "p{u}n" means "use the specified prefix p" and
        $` == '' ? Name.new(nil, $1, $') : Name.new($`, $1, $')
      elsif /:/ =~ name && namespaces.include?($`)
        Name.new($`, namespaces[$`], $')
      elsif namespaces.include?(nil)
        Name.new(nil, namespaces[nil], name)
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
      @namespace_prefix = namespace_prefix && namespace_prefix.dup.freeze
      @namespace_uri = namespace_uri && namespace_uri.dup.freeze
      @local_name = local_name && local_name.dup.freeze
      if @namespace_prefix && /\A#{Pat::Name}\z/ !~ @namespace_prefix
        raise HTree::Error, "invalid namespace prefix: #{@namespace_prefix.inspect}"
      end
      if @local_name && /\A#{Pat::Name}\z/ !~ @local_name
        raise HTree::Error, "invalid local name: #{@local_name.inspect}"
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
        if @namespace_prefix
          "#{@namespace_prefix}:#{@local_name}"
        else
          @local_name.dup
        end
      elsif @local_name
        @local_name.dup
      else
        "xmlns"
      end
    end

    def generate_xml(out='')
      if xmlns?
        if @local_name
          out << "xmlns:#{@local_name}"
        else
          out << "xmlns"
        end
      else
        out << qualified_name
      end
      out
    end
  end

  class STag
    def initialize(name, attributes=[], inherited_namespaces={})
      init_raw_string
      # normalize xml declaration name and attribute value.
      attributes = attributes.map {|aname, val|
        if !(Name === aname) && /\A#{Pat::Name}?(?:\{.*\})?#{Pat::Name}\z/ !~ aname
          raise HTree::Error, "invalid attribute name: #{aname.inspect}"
        end
        if !(Name === aname) && /\Axmlns(?:\z|:)/ =~ aname
          aname = Name.parse_attribute_name(aname, nil)
        end
        val = Text.new(val) unless Text === val
        [aname, val]
      }

      @inherited_namespaces = inherited_namespaces.dup.freeze
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
      @namespaces = make_namespaces.freeze

      if Name === name
        @name = name
      else
        @name = Name.parse_element_name(name, @namespaces)
      end

      @attributes = attributes.map {|aname, text|
        aname = Name.parse_attribute_name(aname, @namespaces) unless Name === aname
        [aname, text]
      }
      @attributes.freeze
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

    def each_attribute
      @attributes.each {|name, text|
        next if name.xmlns?
        yield name, text
      }
    end

    def each_attr
      @attributes.each {|name, text|
        next if name.xmlns?
        yield name.universal_name, text.to_s
      }
    end

    def fetch_attribute(universal_name, *rest)
      each_attribute {|name, text|
        return text if universal_name == name.universal_name
      }
      if block_given?
        yield
      elsif !rest.empty?
        rest[0]
      else
        raise IndexError, "attribute not found: #{universal_name.inspect}"
      end
    end

    def get_attribute(universal_name)
      fetch_attribute(universal_name, nil)
    end

    def get_attr(universal_name)
      text = fetch_attribute(universal_name, nil)
      text && text.to_s
    end

    def generate_xml(out='')
      out << "<#{@name.generate_xml}"
      @attributes.each {|aname, text|
        out << " #{aname.generate_xml}=#{text.generate_xml_attvalue}"
      }
      out << '>'
      out
    end

    def generate_emptytag_xml(out='')
      out << "<#{@name.generate_xml}"
      @attributes.each {|aname, text|
        out << " #{aname.generate_xml}=#{text.generate_xml_attvalue}"
      }
      out << ' />'
      out
    end

    def generate_etag_xml(out='')
      out << "</#{@name.generate_xml}>"
      out
    end
  end

  class ETag
    def initialize(qualified_name)
      init_raw_string
      @qualified_name = qualified_name.dup.freeze
    end
    attr_reader :qualified_name

    def generate_xml(out='')
      out << "</#{@qualified_name}>"
      out
    end
  end

  class BogusETag
    def generate_xml(out='')
      out
    end
  end

end
