require 'htree/nodehier'
require 'htree/tag'

module HTree
  class Doc
    def initialize(children=[])
      @children = children.dup.freeze
    end 
    attr_reader :children

    def generate_xml(out='')
      @children.each {|n| n.generate_xml(out) }
      out
    end

    def root
      es = []
      @children.each {|c| es << c if Elem === c }
      raise Doc::Error, "no element" if es.empty?
      raise Doc::Error, "multiple elements" if 1 < es.length
      es[0]
    end
  end 
  
  class Elem
    class << self
      alias new! new
    end

    AcceptableChild = [
      HTree::Text,
      HTree::ProcIns,
      HTree::Comment,
      HTree::Elem,
      HTree::BogusETag,
      # However XMLDecl and DocType shouldn't appered under Elem, 
      # it is permitted for round-tripness.
      HTree::XMLDecl,
      HTree::DocType,
    ]
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
        # Since name's prefix may not determined,
        # ETag cannot create.
        new!(STag.new(name, attrs), children)
      end
    end

    def initialize(stag, children=nil, etag=nil)
      unless stag.class == STag
        raise Elem::Error, "HTree::STag expected: #{stag.inspect}"
      end
      unless !children || children.all? {|c| AcceptableChild.include? c.class }
        raise Elem::Error, "array of HTree expected: #{children.find_all {|c| !AcceptableChild.include?(c.class) }.inspect}"
      end
      unless !etag || etag.class == ETag
        raise Elem::Error, "HTree::ETag expected: #{etag.inspect}"
      end
      @stag = stag
      @children = (children ? children.dup : []).freeze
      @empty = children == nil && etag == nil
      @etag = etag
    end
    attr_reader :children, :stag, :etag
    
    def name; @stag.universal_name end
    def qualified_name; @stag.qualified_name end

    def empty_element?
      @empty
    end

    def generate_xml(out='')
      if @empty
        @stag.generate_emptytag_xml(out)
      else
        @stag.generate_xml(out)
        @children.each {|n| n.generate_xml(out) }
        @stag.generate_etag_xml(out)
      end
      out
    end
  end 
end
