require 'htree/text'

class HTree
  class STag < Markup
    def initialize(name, attributes=[], inherited_namespaces={})
      @attributes = attributes.map {|aname, val|
        val = Text.new(val) unless Text === val
        [aname, val]
      }
      @inherited_namespaces = inherited_namespaces

      init_namespace(name)
    end
    attr_reader :qualified_name, :attributes, :inherited_namespaces

    def init_namespace(name)
      @namespaces = make_namespaces
      if /\{(.*)\}/ =~ name
        @namespace_uri = $1
        @namespace_prefix = $`.empty? ? nil : $`
        @local_name = $'
        @qualified_name = @namespace_prefix ? "#{@namespace_prefix}:#{@local_name}" : nil
        @universal_name = "{#{@namespace_uri}}#{@local_name}"
      else
        @qualified_name = name
        if /:/ =~ @qualified_name && @namespaces.include?($`)
          @namespace_prefix = $`
          @namespace_uri = @namespaces[@namespace_prefix]
          @local_name = $'
          @universal_name = "{#{@namespace_uri}}#{@local_name}"
        elsif @namespaces.include?(nil)
          @namespace_prefix = nil
          @namespace_uri = @namespaces[nil]
          @local_name = @qualified_name
          @universal_name = "{#{@namespace_uri}}#{@local_name}"
        else
          @namespace_prefix = nil
          @namespace_uri = nil
          @local_name = @qualified_name
          @universal_name = @qualified_name
        end
      end
    end
    attr_reader :namespace_prefix,
                :namespace_uri,
                :local_name,
                :universal_name,
                :namespaces

    def make_namespaces(inherited_namespaces=@inherited_namespaces)
      namespaces = inherited_namespaces.dup
      each_namespace_attribute {|prefix, uri|
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
      @attributes.each {|name, text|
        case name
        when /\Axmlns\z/
          uri = text.to_s
          yield nil, (uri.empty? ? nil : uri)
        when /\Axmlns:/
          yield $', text.to_s
        end
      }
    end

    def each_attribute_info
      @attributes.each {|name, text|
        next if /\A(?:xmlns\z|xmlns:)/ =~ name
        if /\{(.*)\}/ =~ name
          namespace_uri = $1
          prefix = $`.empty? ? nil : $`
          lname = $'
        elsif /:/ =~ name && @namespaces.include?($`)
          namespace_uri = @namespaces[$`]
          prefix = $`
          lname = $'
        else
          namespace_uri = nil
          prefix = nil
          lname = name
        end
        yield namespace_uri, prefix, lname, text
      }
    end

    def each_attribute_text
      each_attribute_info {|namespace_uri, prefix, lname, text|
        uname = namespace_uri ? "{#{namespace_uri}}#{lname}" : lname
        yield uname, text
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
      result = "<#{@qualified_name || @universal_name}"
      @attributes.each {|aname, text|
        result << " #{aname}=#{text.to_xml_attvalue}"
      }
      result << '>'
    end

    def to_emptytag_xml
      result = "<#{@qualified_name || @universal_name}"
      @attributes.each {|aname, text|
        result << " #{aname}=#{text.to_xml_attvalue}"
      }
      result << ' />'
    end

    def to_etag_xml
      "</#{@qualified_name || @universal_name}>"
    end

  end

  class ETag < Markup
    def initialize(qualified_name)
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
