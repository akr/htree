require 'htree/nodehier'
require 'htree/tag'

module HTree
  class Doc
    def initialize(children=nil)
      @children = children
    end 
    attr_reader :children

    def to_xml
      @children.map {|n| n.to_xml }.join('')
    end

  end 
  
  class Elem
    class << self
      alias new! new
    end

    def Elem.new(name, *args)
      if args.empty?
        new!(STag.new(name))
      else
        attrs = []
        children = []
        args.flatten.each {|arg|
          case arg
          when Hash
            arg.each {|k, v| attrs << [k, v] }
          when HTree
            children << arg
          when String
            children << Text.new(arg)
          else
            raise "unexpected argument: #{arg.inspect}"
          end
        }
        new!(STag.new(name, attrs), children, ETag.new(name))
      end
    end

    def initialize(stag, children=nil, etag=nil)
      unless stag.class == STag
        raise "HTree::STag expected: #{stag.inspect}"
      end
      unless !children || children.all? {|c| HTree === c }
        raise "HTree array expected: #{children.inspect}"
      end
      unless !etag || etag.class == ETag
        raise "HTree::ETag expected: #{etag.inspect}"
      end
      @stag = stag
      @children = children
      @etag = etag
    end
    attr_reader :children, :stag, :etag
    
    def name; @stag.universal_name end
    def qualified_name; @stag.qualified_name end

    def to_xml
      if @children
        @stag.to_xml + @children.map {|n| n.to_xml }.join('') + @stag.to_etag_xml
      else
        @stag.to_emptytag_xml
      end
    end
  end 
end
