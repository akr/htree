require 'htree/modules'
require 'htree/tag'
require 'htree/context'

module HTree
  class Elem
    # :stopdoc:
    class << self
      alias new! new
    end
    # :startdoc:

    def Elem.new(name, *args)
      attrs = []
      children = []
      context = nil
      args.flatten.each {|arg|
        arg = arg.to_node if HTree::Location === arg
        case arg
        when Context
          raise ArgumentError, "multiple context" if context
          context = arg
        when Hash
          arg.each {|k, v| attrs << [k, v] }
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
      context ||= DefaultContext
      if children.empty? && args.all? {|arg| Hash === arg || Context === arg }
        children = nil
      end
      new!(STag.new(name, attrs, context), children)
    end

    def initialize(stag, children=nil, etag=nil) # :notnew:
      unless stag.class == STag
        raise TypeError, "HTree::STag expected: #{stag.inspect}"
      end
      unless !children || children.all? {|c| c.kind_of?(HTree::Node) and !c.kind_of?(HTree::Doc) }
        unacceptable = children.reject {|c| c.kind_of?(HTree::Node) and !c.kind_of?(HTree::Doc) }
        unacceptable = unacceptable.map {|uc| uc.inspect }.join(', ')
        raise TypeError, "Unacceptable element child: #{unacceptable}"
      end
      unless !etag || etag.class == ETag
        raise TypeError, "HTree::ETag expected: #{etag.inspect}"
      end
      @stag = stag
      @children = (children ? children.dup : []).freeze
      @empty = children == nil && etag == nil
      @etag = etag
    end

    # +children+ returns children nodes as an array.
    def children
      @children.dup
    end

    def context; @stag.context end

    # +element_name+ returns the name of the element name as a Name object.
    def element_name() @stag.element_name end

    def empty_element?
      @empty
    end

    def each_attribute(&block) # :yields: attr_name, attr_text
      @stag.each_attribute(&block)
    end

    def get_subnode(index)
      case index
      when String
        name = Name.parse_attribute_name(index, DefaultContext)
        update_attribute_hash[name.universal_name]
      when Name
        update_attribute_hash[index.universal_name]
      when Integer
        @children[index]
      else
        raise TypeError, "invalid index: #{index.inspect}"
      end
    end

    def subst_subnode(arg_hash)
      hash = {}
      arg_hash.each_pair {|index, value|
        case index
        when Name, Integer
        when String
          index = Name.parse_attribute_name(index, DefaultContext)
        else
          raise TypeError, "invalid index: #{index.inspect}"
        end
        if hash.include? index
          raise ArgumentError, "duplicate index: #{index.inspect}"
        end
        hash[index] = value
      }

      attrs = {}
      @stag.attributes.each {|k, v|
        attrs[k] = v
      }

      children_left = []
      children = @children.dup
      children_right = []

      hash.each_pair {|index, value|
        case index
        when Name
          if value
            attrs[index] = value
          else
            attrs.delete(index) {
              raise ArgumentError, "nonexist index: #{index.inspect}"
            }
          end
        when Integer
          if index < 0
            children_left << value
          elsif children.length <= index
            children_right << value
          else
            children[index] = value
          end
        end
      }

      children = [children_left, children, children_right].flatten.compact

      if children.empty? && @empty
        Elem.new(
          @stag.element_name,
          attrs,
          @stag.context)
      else 
        Elem.new(
          @stag.element_name,
          attrs,
          children,
          @stag.context)
      end
    end
  end 

  module Elem::Trav
    def update_attribute_hash # :nodoc:
      if defined?(@attribute_hash)
        @attribute_hash
      else
        h = {}
        each_attribute {|name, text|
          h[name.universal_name] = text
        }
        @attribute_hash = h
      end
    end
  end
end
