require 'htree/modules'

module HTree
  class Doc
    # :stopdoc:
    class << self
      alias new! new
    end
    # :startdoc:

    def Doc.new(*args)
      children = []
      args.flatten.each {|arg|
        case arg
        when HTree::Doc
          arg.children.each {|c|
            next if HTree::XMLDecl === c
            next if HTree::DocType === c
            children << c
          }
        when HTree::Node
          children << arg
        when String
          children << Text.new(arg)
        else
          raise TypeError, "unexpected argument: #{arg.inspect}"
        end
      }
      new!(children)
    end

    def initialize(children=[]) # :notnew:
      @children = children.dup.freeze
      unless @children.all? {|c| c.kind_of?(HTree::Node) and !c.kind_of?(HTree::Doc) }
        unacceptable = @children.reject {|c| c.kind_of?(HTree::Node) and !c.kind_of?(HTree::Doc) }
        unacceptable = unacceptable.map {|uc| uc.inspect }.join(', ')
        raise TypeError, "Unacceptable document child: #{unacceptable}"
      end
    end 
    attr_reader :children

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
