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

    # The first argument _name_ should be an instance of String or HTree::Name.
    #
    # The rest of arguments should be a sequence of follows.
    # [Hash object] used as attributes.
    # [String object] specified string is converted to HTree::Text.
    # [HTree::Node object] used as a child.
    # [Array of String and HTree::Node] used as children.
    # [HTree::Doc object]
    #   used as children.
    #   It is expanded except HTree::XMLDecl and HTree::DocType objects.
    # [HTree::Context object]
    #   used as as context which represents XML namespaces.
    #   This should apper once at most.
    #
    # HTree::Location object is accepted just as HTree::Node.
    #
    # If the rest arguments consists only
    # Hash and HTree::Context, empty element is created.
    #
    #   p HTree::Elem.new("e").empty_element?     # => true
    #   p HTree::Elem.new("e", []).empty_element? # => false
    def Elem.new(name, *args)
      attrs = []
      children = []
      context = nil
      args.each {|arg|
        arg = arg.to_node if HTree::Location === arg
        case arg
        when Context
          raise ArgumentError, "multiple context" if context
          context = arg
        when Hash
          arg.each {|k, v| attrs << [k, v] }
        when Array
          arg.each {|c|
            c = c.to_node if HTree::Location === arg
            case c
            when HTree::Node
              children << c
            when String
              children << Text.new(c)
            else
              raise TypeError, "unexpected argument: #{arg.inspect}"
            end
          }
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

    #   elem.subst_subnode(pairs) -> elem
    #
    # The argument _pairs_ should be a hash or an assocs.
    #
    # The key of pairs should be one of following.
    # [HTree::Name or String object] attribute name.
    # [Integer object] child index.
    #
    # The value of pairs should be one of follows.
    # [HTree::Node object] specified object is used as is.
    # [String object] specified string is converted to HTree::Text
    # [Array of above] specified HTree::Node and String is used in that order.
    # [nil] delete corresponding node.
    #
    #   pp HTree('<r><a/><b/><c/><r/>').root.subst_subnode({0=>HTree('<x/>'), 2=>HTree('<z/>')})
    #   # =>
    #   {elem <r> {emptyelem <x>} {emptyelem <b>} {emptyelem <z>} {emptyelem <r>}}
    #
    #   pp HTree('<r><a/><b/><c/></r>').root.subst_subnode([[0,HTree('<x/>')], [2,HTree('<z/>')]])
    #   # =>
    #   {elem <r> {emptyelem <x>} {emptyelem <b>} {emptyelem <z>}}
    #
    def subst_subnode(pairs)
      hash = {}
      pairs.each {|index, value|
        case index
        when Name, Integer
        when String
          index = Name.parse_attribute_name(index, DefaultContext)
        else
          raise TypeError, "invalid index: #{index.inspect}"
        end
        case value
        when Node
          value = [value]
        when String
          value = [value]
        when Array
          value = value.dup
        when nil
          value = []
        else
          raise TypeError, "invalid value: #{value.inspect}"
        end
        value.map! {|v|
          case v
          when Node
            v
          when String
            Text.new(v)
          else
            raise TypeError, "invalid value: #{v.inspect}"
          end
        }
        if !hash.include?(index)
          hash[index] = []
        end
        hash[index].concat value
      }

      attrs = []
      @stag.attributes.each {|k, v|
        if hash.include? k
          v = hash[k]
          if !v.empty?
            attrs << {k=>Text.concat(*v)}
          end
          hash.delete k
        else
          attrs << {k=>v}
        end
      }
      hash.keys.each {|k|
        if Name === k
          v = hash[k]
          if !v.empty?
            attrs << {k=>Text.concat(*v)}
          end
          hash.delete k
        end
      }

      children_left = []
      children = @children.dup
      children_right = []

      hash.keys.sort.each {|index|
        value = hash[index]
        if index < 0
          children_left << value
        elsif children.length <= index
          children_right << value
        else
          children[index] = value
        end
      }

      children = [children_left, children, children_right].flatten

      if children.empty? && @empty
        Elem.new(
          @stag.element_name,
          @stag.context,
          *attrs)
      else 
        Elem.new(
          @stag.element_name,
          @stag.context,
          children,
          *attrs)
      end
    end
  end 

  module Elem::Trav
    private
    def update_attribute_hash
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
