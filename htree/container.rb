require 'htree/nodehier'
require 'htree/tag'

module HTree
  class Doc
    def initialize(children=nil)
      @children = children
    end 
    attr_reader :children

    def generate_xml
      @children.map {|n| n.generate_xml }.join('')
    end

  end 
  
  class Elem
    class << self
      alias new! new
    end

    AcceptableChild = [HTree::Text, HTree::ProcIns, HTree::Comment, HTree::Elem]
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
          when *AcceptableChild
            children << arg
          when HTree::Doc
            arg.children.each {|c|
              next if HTree::XMLDecl === c
              next if HTree::DocType === c
              children << c
            }
          when String
            children << Text.new(arg)
          else
            raise Elem::Error, "unexpected argument: #{arg.inspect}"
          end
        }
        new!(STag.new(name, attrs), children, ETag.new(name))
      end
    end

    def initialize(stag, children=nil, etag=nil)
      unless stag.class == STag
        raise Elem::Error, "HTree::STag expected: #{stag.inspect}"
      end
      unless !children || children.all? {|c| AcceptableChild.include? c.class }
        raise Elem::Error, "HTree array expected: #{children.inspect}"
      end
      unless !etag || etag.class == ETag
        raise Elem::Error, "HTree::ETag expected: #{etag.inspect}"
      end
      @stag = stag
      @children = children
      @etag = etag
    end
    attr_reader :children, :stag, :etag
    
    def name; @stag.universal_name end
    def qualified_name; @stag.qualified_name end

    def generate_xml
      if @children
        @stag.generate_xml + @children.map {|n| n.generate_xml }.join('') + @stag.generate_etag_xml
      else
        @stag.generate_emptytag_xml
      end
    end
  end 
end
