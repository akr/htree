require 'htree/modules'

module HTree
  class Loc
    # - Loc.new(target_node) => loc
    # - Loc.new(parent_loc, index) => loc
    def initialize(base, *rest)
      case base
      when Loc
        if rest.length != 1
          raise ArgumentError, "not index argument: #{rest[0].inspect}"
        end
        index, = rest
        @parent = base
        @index = index
        @node = @parent.node.get_subnode(@index)
      when Node
        if rest.length != 0
          raise ArgumentError, "extra argument: #{rest.inspect}"
        end
        @parent = nil
        @index = nil
        @node = base
      else
        raise TypeError, "invalid base argument: #{base.inspect}"
      end
      extend @node.class::LocMixin if @node != nil
    end
    attr_reader :parent, :index, :node

    def get_subloc(*indexes)
      loc = self
      indexes.each {|index|
        loc = Loc.new(loc, index)
      }
      loc
    end

    # returns an array containing from location's root to itself.
    def loc_list
      loc = self
      result = [self]
      while loc = loc.parent
        result << loc
      end
      result.reverse!
      result
    end

    # :stopdoc:
    def pretty_print(q)
      q.object_group(self) {
        q.text ':'
        q.breakable
        loc_list.each {|loc|
          if loc.parent
            q.text '/'
            q.text loc.parent.node.find_loc_step(loc.index)
          else
            q.text loc.node.node_test
          end
        }
      }
    end
    # :startdoc:
  end

  # :stopdoc:
  module Container
    def find_loc_step(index) # :nodoc:
      if index < 0 || @children.length <= index
        return "*[#{index}]"
      end
      child = @children[index]
      node_test = child.node_test

      n = 0
      j = nil
      @children.each_with_index {|c, i|
        if c.node_test == node_test
          n += 1
          j = n if i == index
        end
      }
      if n != 1
        "#{node_test}[#{j}]"
      else
        node_test
      end
    end
  end

  class Elem
    def find_loc_step(index)
      return super if Integer === index
      if String === index
        index = Name.parse_attribute_name(index, DefaultContext)
      end
      unless Name === index
        raise TypeError, "invalid index: #{index.inspect}"
      end
      "@#{index.qualified_name}"
    end
  end

  class Doc; def node_test() 'doc()' end end
  class Elem; alias node_test qualified_name end
  class Text; def node_test() 'text()' end end
  class BogusETag; def node_test() 'bogus-etag()' end end
  class XMLDecl; def node_test() 'xml-declaration()' end end
  class DocType; def node_test() 'doctype()' end end
  class ProcIns; def node_test() 'processing-instruction()' end end
  class Comment; def node_test() 'comment()' end end
  # :startdoc:

  module Node::LocMixin
  end

  module ContainerLocMixin
    include Node::LocMixin
  end

  module Elem::LocMixin
    include ContainerLocMixin
  end

  module Doc::LocMixin
    include ContainerLocMixin
  end
end
