require 'htree/modules'
require 'htree/elem'
require 'htree/inspect'

module HTree
  module Node
    # creates a location object which points to self.
    def make_loc
      self.class::Loc.new(nil, nil, self)
    end

    # return self.
    def to_node
      self
    end
  end

  # :stopdoc:
  class Doc; def node_test_string() 'doc()' end end
  class Elem; def node_test_string() @stag.element_name.qualified_name end end
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

      return @loc_step_children[index].dup if defined? @loc_step_children

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

      return @loc_step_children[index].dup
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

module HTree::Location
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
    if self.class != @node.class::Loc
      raise ArgumentError, "invalid location class: #{self.class} should be #{node.class::Loc}"
    end
    @subloc = {}
  end
  attr_reader :parent, :index, :node
  alias to_node node

  # return self.
  def make_loc
    self
  end

  # +get_subnode+ returns a location object which points to a subnode
  # indexed by _index_. 
  def get_subnode(index)
    return @subloc[index] if @subloc.include? index
    node = @node.get_subnode(index)
    @subloc[index] = node.class::Loc.new(self, index, node)
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

  # +path+ returns the path of the location.
  #
  #   l = HTree.parse("<a><b>x</b><b/><a/>").make_loc
  #   l = l.get_subnode(0).get_subnode(0).get_subnode(0)
  #   p l.path # => "doc()/a/b[1]/text()"
  def path
    result = ''
    loc_list.each {|loc|
      if parent = loc.parent
        result << '/' << parent.node.find_loc_step(loc.index)
      else
        result << loc.node.node_test_string
      end
    }
    result
  end

  # :stopdoc:
  def pretty_print(q)
    q.group(1, '#<HTree::Location', '>') {
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
  alias inspect pretty_print_inspect
  # :startdoc:
end

module HTree::Container::Loc
  # +children+ returns an array of child locations.
  def children
    (0...@node.children.length).map {|i| get_subnode(i) }
  end
end

class HTree::Elem::Loc
  def context() @node.context end

  # +element_name+ returns the name of the element name as a Name object.
  def element_name() @node.element_name end

  def empty_element?() @node.empty_element? end

  # +each_attribute+ iterates over each attributes.
  def each_attribute
    @node.each_attribute {|attr_name, attr_text|
      attr_loc = get_subnode(attr_name)
      yield attr_name, attr_loc
    }
  end
end
