require 'htree/scan' # for Pat::Nmtoken
require 'htree/context'

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
    def Name.parse_element_name(name, context)
      if /\{(.*)\}/ =~ name
        # In to_xml, 
        # "{u}n" means "use default namespace",
        # "p{u}n" means "use the specified prefix p" and
        $` == '' ? Name.new(nil, $1, $') : Name.new($`, $1, $')
      elsif /:/ =~ name && context.namespace_uri($`)
        Name.new($`, context.namespace_uri($`), $')
      elsif context.namespace_uri(nil)
        Name.new(nil, context.namespace_uri(nil), name)
      else
        Name.new(nil, nil, name)
      end
    end

    def Name.parse_attribute_name(name, context)
      if name == 'xmlns'
        Name.new('xmlns', nil, nil)
      elsif /\Axmlns:/ =~ name
        Name.new('xmlns', nil, $')
      elsif /\{(.*)\}/ =~ name
        case $`
        when ''; Name.new(nil, $1, $')
        else Name.new($`, $1, $')
        end
      elsif /:/ =~ name && context.namespace_uri($`)
        Name.new($`, context.namespace_uri($`), $')
      else
        Name.new(nil, nil, name)
      end
    end

    def initialize(namespace_prefix, namespace_uri, local_name)
      @namespace_prefix = namespace_prefix && namespace_prefix.dup.freeze
      @namespace_uri = namespace_uri && namespace_uri.dup.freeze
      @local_name = local_name && local_name.dup.freeze
      if @namespace_prefix && /\A#{Pat::Nmtoken}\z/ !~ @namespace_prefix
        raise HTree::Error, "invalid namespace prefix: #{@namespace_prefix.inspect}"
      end
      if @local_name && /\A#{Pat::Nmtoken}\z/ !~ @local_name
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

    def to_s
      if @namespace_uri
        if @namespace_prefix
          "#{@namespace_prefix}{#{@namespace_uri}}#{@local_name}"
        else
          "{#{@namespace_uri}}#{@local_name}"
        end
      elsif @local_name
        @local_name.dup
      else
        "xmlns"
      end
    end
  end
end
