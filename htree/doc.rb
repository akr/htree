require 'htree/nodehier'

module HTree
  class Doc
    class << self
      alias new! new
    end

    AcceptableChild = [
      HTree::Text,
      HTree::ProcIns,
      HTree::Comment,
      HTree::Elem,
      HTree::XMLDecl,
      HTree::DocType,
      HTree::BogusETag,
    ]
    def Doc.new(*args)
      children = []
      args.flatten.each {|arg|
        case arg
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
          raise TypeError, "unexpected argument: #{arg.inspect}"
        end
      }
      new!(children)
    end

    def initialize(children=[])
      @children = children.dup.freeze
      unless @children.all? {|c| AcceptableChild.include? c.class }
        unacceptable = @children.reject {|c| AcceptableChild.include? c.class }
        unacceptable = unacceptable.map {|uc| uc.inspect }.join(', ')
        raise TypeError, "Unacceptable document child: #{unacceptable}"
      end
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

    def get_subnode(index)
      unless Integer === index
        raise TypeError, "invalid index: #{index.inspect}"
      end
      @children[index]
    end

    def subst_subnode(hash)
      hash.each_pair {|index, value|
        unless Integer === index
          raise TypeError, "invalid index: #{index.inspect}"
        end
      }

      children_left = []
      children = @children.dup
      children_right = []

      hash.each_pair {|index, value|
        if index < 0
          children_left << value
        elsif children.length <= index
          children_right << value
        else
          children[index] = value
        end
      }

      children = [children_left, children, children_right].flatten.compact
      Doc.new(children)
    end

    def root
      es = []
      @children.each {|c| es << c if Elem === c }
      raise HTree::Error, "no element" if es.empty?
      raise HTree::Error, "multiple elements" if 1 < es.length
      es[0]
    end
  end 
end
