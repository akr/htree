require 'htree/modules'

module HTree
  module Node
    # creates a location object which points to self.
    def make_loc
      self.class::Location.new(nil, nil, self)
    end
  end

  # :stopdoc:
  class Doc; def node_test_string() 'doc()' end end
  class Elem; alias node_test_string qualified_name end
  class Text; def node_test_string() 'text()' end end
  class BogusETag; def node_test_string() 'bogus-etag()' end end
  class XMLDecl; def node_test_string() 'xml-declaration()' end end
  class DocType; def node_test_string() 'doctype()' end end
  class ProcIns; def node_test_string() 'processing-instruction()' end end
  class Comment; def node_test_string() 'comment()' end end

  module Container
    def find_loc_step(index)
      if index < 0 || @children.length <= index
        return "*[#{index}]"
      end

      return @loc_step_children[index] if defined? @loc_step_children

      count = {}
      count.default = 0

      steps = []

      @children.each {|c|
        node_test = c.node_test_string
        count[node_test] += 1
        steps << [node_test, count[node_test]]
      }

      @loc_step_children = []
      steps.each {|node_test, i|
        if count[node_test] == 1
          @loc_step_children << node_test
        else
          @loc_step_children << "#{node_test}[#{i}]"
        end
      }

      return @loc_step_children[index]
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
  # :startdoc:
end

module HTree::Loc
  def initialize(parent, index, node) # :nodoc:
    if parent
      @parent = parent
      @index = index
      @node = parent.node.get_subnode(index)
      if !@node.equal?(node)
        raise ArgumentError, "unexpected node"
      end
    else
      @parent = nil
      @index = nil
      @node = node
    end
    if self.class != @node.class::Location
      raise ArgumentError, "invalid location class: #{self.class} should be #{node.class::Location}"
    end
    @subloc = {}
  end
  attr_reader :parent, :index, :node
  alias to_node node

  # +get_subnode+ returns a location object which points to a subnode indexed by _index_. 
  def get_subnode(index)
    return @subloc[index] if @subloc.include? index
    node = @node.get_subnode(index)
    @subloc[index] = node.class::Location.new(self, index, node)
  end

  # +loc_list+ returns an array containing from location's root to itself.
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
    q.group(1, '#<HTree::Loc', '>') {
      q.text ':'
      q.breakable
      loc_list.each {|loc|
        if parent = loc.parent
          q.text '/'
          q.breakable ''
          q.text parent.node.find_loc_step(loc.index)
        else
          q.text loc.node.node_test_string
        end
      }
    }
  end
  # :startdoc:
end
