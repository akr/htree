require 'htree/nodehier'
require 'htree/tag'

module HTree
  class Doc
    def initialize(children=[])
      @children = children.dup.freeze
    end 
    attr_reader :children

    def generate_xml(out='')
      xmldecl = false
      doctypedecl = false
      @children.each {|n|
        if n.respond_to? :generate_prolog_xmldecl_xml
          n.generate_prolog_xmldecl_xml(out) unless xmldecl
          xmldecl = true
        elsif n.respond_to? :generate_prolog_doctypedecl_xml
          n.generate_prolog_doctypedecl_xml(out) unless doctypedecl
          doctypedecl = true
        else
          n.generate_xml(out)
        end
      }
      out
    end

    def root
      es = []
      @children.each {|c| es << c if Elem === c }
      raise HTree::Error, "no element" if es.empty?
      raise HTree::Error, "multiple elements" if 1 < es.length
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
      # Following XMLDecl, XMLDecl and BogusETag is invalid as a child of Elem.
      # So their generate_xml generates empty string.
      HTree::XMLDecl,
      HTree::DocType,
      HTree::BogusETag,
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
            raise HTree::Error, "unexpected argument: #{arg.inspect}"
          end
        }
        # Since name's prefix may not determined,
        # ETag cannot create.
        new!(STag.new(name, attrs), children)
      end
    end

    def initialize(stag, children=nil, etag=nil)
      unless stag.class == STag
        raise HTree::Error, "HTree::STag expected: #{stag.inspect}"
      end
      unless !children || children.all? {|c| AcceptableChild.include? c.class }
        raise HTree::Error, "array of HTree expected: #{children.find_all {|c| !AcceptableChild.include?(c.class) }.inspect}"
      end
      unless !etag || etag.class == ETag
        raise HTree::Error, "HTree::ETag expected: #{etag.inspect}"
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
