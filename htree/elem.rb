require 'htree/nodehier'
require 'htree/tag'
require 'htree/context'

module HTree
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
        context = nil
        args.flatten.each {|arg|
          case arg
          when Context
            raise ArgumentError, "multiple context" if context
            context = arg
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
        context ||= DefaultContext
        # Since name's prefix may not determined,
        # ETag cannot create.
        new!(STag.new(name, attrs, context), children)
      end
    end

    def initialize(stag, children=nil, etag=nil)
      unless stag.class == STag
        raise HTree::Error, "HTree::STag expected: #{stag.inspect}"
      end
      unless !children || children.all? {|c| AcceptableChild.include? c.class }
        raise HTree::Error, "Unacceptable child: #{children.find_all {|c| !AcceptableChild.include?(c.class) }.inspect}"
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
    def element_name; @stag.element_name end

    def attributes
      result = {}
      @stag.each_attribute {|name, text|
        result[name] = text
      }
      result
    end

    def each_attribute(&block); @stag.each_attribute(&block) end
    def each_attr(&block); @stag.each_attr(&block) end
    def fetch_attribute(uname, *rest, &block); @stag.fetch_attribute(uname, *rest, &block) end
    def fetch_attr(uname, *rest, &block); @stag.fetch_attr(uname, *rest, &block) end
    def get_attribute(uname, *rest, &block); @stag.get_attribute(uname, *rest, &block) end
    def get_attr(uname, *rest, &block); @stag.get_attr(uname, *rest, &block) end

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

    def get_subnode(index)
      case index
      when String
        name = Name.parse_attribute_name(index, DefaultContext)
        @stag.get_attribute(name.universal_name)
      when Name
        @stag.get_attribute(index.universal_name)
      when Integer
        @children[index]
      else
        raise ArgumentError, "invalid index: #{index.inspect}"
      end
    end

    def subst_subnode(arg_hash)
      hash = {}
      arg_hash.each_pair {|index, value|
        case index
        when Name, Integer
          hash[index] = value
        when String
          name = Name.parse_attribute_name(index, DefaultContext)
          if hash.include? name
            raise ArgumentError, "duplicate index: #{index.inspect}"
          end
          hash[name] = value
        else
          raise ArgumentError, "invalid index: #{index.inspect}"
        end
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

      Elem.new(
        @stag.element_name,
        attrs,
        children_left,
        children,
        children_right,
        @stag.context)
    end
  end 
end
