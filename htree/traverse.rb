require 'htree/doc'
require 'htree/elem'
require 'htree/loc'
require 'htree/extract_text'

module HTree
  module Container::Trav
    # +each_child+ iterates over each child.
    def each_child(&block) # :yields: child_node
      children.each(&block)
      nil
    end

    # +each_child_with_index+ iterates over each child.
    def each_child_with_index(&block) # :yields: child_node, index
      children.each_with_index(&block)
      nil
    end

    # +find_element+ searches an element which universal name is specified by
    # the arguments. 
    # It returns nil if not found.
    def find_element(*names)
      traverse_element(*names) {|e| return e }
      nil
    end

    # +traverse_element+ traverses elements in the tree.
    # It yields elements in depth first order.
    #
    # If _names_ are empty, it yields all elements.
    # If non-empty _names_ are given, it should be list of universal names.
    # 
    # A nested element is yielded in depth first order as follows.
    #
    #   t = HTree('<a id=0><b><a id=1 /></b><c id=2 /></a>') 
    #   t.traverse_element("a", "c") {|e| p e}
    #   # =>
    #   {elem <a id="0"> {elem <b> {emptyelem <a id="1">} </b>} {emptyelem <c id="2">} </a>}
    #   {emptyelem <a id="1">}
    #   {emptyelem <c id="2">}
    #
    # Universal names are specified as follows.
    #
    #   t = HTree(<<'End')
    #   <html>
    #   <meta name="robots" content="index,nofollow">
    #   <meta name="author" content="Who am I?">    
    #   </html>
    #   End
    #   t.traverse_element("{http://www.w3.org/1999/xhtml}meta") {|e| p e}
    #   # =>
    #   {emptyelem <{http://www.w3.org/1999/xhtml}meta name="robots" content="index,nofollow">}
    #   {emptyelem <{http://www.w3.org/1999/xhtml}meta name="author" content="Who am I?">}
    #
    def traverse_element(*names, &block) # :yields: element
      if names.empty?
        traverse_all_element(&block)
      else
        name_set = {}
        names.each {|n| name_set[n] = true }
        traverse_some_element(name_set, &block)
      end
      nil
    end
  end

  # :stopdoc:
  module Doc::Trav
    def traverse_all_element(&block)
      children.each {|c| c.traverse_all_element(&block) }
    end
  end

  module Elem::Trav
    def traverse_all_element(&block)
      yield self
      children.each {|c| c.traverse_all_element(&block) }
    end
  end

  module Leaf::Trav
    def traverse_all_element
    end
  end

  module Doc::Trav
    def traverse_some_element(name_set, &block)
      children.each {|c| c.traverse_some_element(name_set, &block) }
    end
  end

  module Elem::Trav
    def traverse_some_element(name_set, &block)
      yield self if name_set.include? self.name
      children.each {|c| c.traverse_some_element(name_set, &block) }
    end
  end

  module Leaf::Trav
    def traverse_some_element(name_set)
    end
  end
  # :startdoc:

  module Container::Trav
    # +filter+ rebuilds the tree without some components.
    #
    #   node.filter {|descent_node| predicate } -> node
    #   loc.filter {|descent_loc| predicate } -> node
    #
    # +filter+ yields each node except top node.
    # If given block returns false, corresponding node is dropped.
    # If given block returns true, corresponding node is retained and
    # inner nodes are examined.
    #
    # +filter+ returns an node.
    # It doesn't return location object even if self is location object.
    #
    def filter(&block)
      subst = {}
      each_child_with_index {|c, i|
        if yield c
          if Elem === c.to_node
            subst[i] = c.filter(&block)
          else
            subst[i] = c
          end
        else
          subst[i] = nil
        end
      }
      to_node.subst_subnode(subst)
    end
  end

  class Doc
    def title
      e = find_element('title',
        '{http://www.w3.org/1999/xhtml}title',
        '{http://purl.org/rss/1.0/}title',
        '{http://my.netscape.com/rdf/simple/0.9/}title')
      e && e.extract_text.to_s
    end

    def author
      traverse_element('meta',
        '{http://www.w3.org/1999/xhtml}meta') {|e|
        begin
          next unless e.fetch_attr('name').downcase == 'author'
          author = e.fetch_attr('content').strip
          return author if !author.empty?
        rescue IndexError
        end
      }

      traverse_element('link',
        '{http://www.w3.org/1999/xhtml}link') {|e|
        begin
          next unless e.fetch_attr('rev').downcase == 'made'
          author = e.fetch_attr('title').strip
          return author if !author.empty?
        rescue IndexError
        end
      } 

      if root.name == '{http://www.w3.org/1999/02/22-rdf-syntax-ns#}RDF'
        if channel = find_element('{http://purl.org/rss/1.0/}channel')
          channel.traverse_element('{http://purl.org/dc/elements/1.1/}creator') {|e|
            begin
              author = e.extract_text.to_s.strip
              return author if !author.empty?
            rescue IndexError
            end
          }
          channel.traverse_element('{http://purl.org/dc/elements/1.1/}publisher') {|e|
            begin
              author = e.extract_text.to_s.strip
              return author if !author.empty?
            rescue IndexError
            end
          }
        end
      end

      nil
    end

  end

end
