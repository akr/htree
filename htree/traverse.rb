require 'htree/container'

module HTree
  module Container
    def each_child
      @children.each {|c| yield c }
    end
  end

  # traverse_element
  module Container
    def traverse_element(*names, &block)
      if names.empty?
        traverse_all_element(&block)
      else
        name_set = {}
        names.each {|n| name_set[n] = true }
        traverse_some_element(name_set, &block)
      end
    end
  end

  # traverse_all_element
  class Doc
    def traverse_all_element(&block)
      @children.each {|c| c.traverse_all_element(&block) }
      nil
    end
  end

  class Elem
    def traverse_all_element(&block)
      yield self
      @children.each {|c| c.traverse_all_element(&block) }
      nil
    end
  end

  module Leaf
    def traverse_all_element
      nil
    end
  end

  # traverse_some_element
  class Doc
    def traverse_some_element(name_set, &block)
      @children.each {|c| c.traverse_some_element(name_set, &block) }
      nil
    end
  end

  class Elem
    def traverse_some_element(name_set, &block)
      yield self if name_set.include? self.name
      @children.each {|c| c.traverse_some_element(name_set, &block) }
      nil
    end
  end

  module Leaf
    def traverse_some_element(name_set)
      nil
    end
  end

  # each_with_path
  module Container
    def each_with_path(prefix=nil)
      return unless @children
      count = {}
      @children.each {|c|
        node_test = c.node_test
        count[node_test] ||= 0
        count[node_test] += 1
      }
      pos = {}
      @children.each {|c|
        node_test = c.node_test
        pos[node_test] ||= 0
        n = pos[node_test] += 1
        child_path = node_test
        child_path += "[#{n}]" unless n == 1 && count[node_test] == 1
        if prefix
          yield c, "#{prefix}/#{child_path}"
        else
          yield c, child_path
        end
      }
    end
  end

  class Elem; alias node_test qualified_name; end
  class XMLDecl; def node_test; 'xml-declaration()' end end
  class DocType; def node_test; 'doctype()' end end
  class ProcIns; def node_test; 'processing-instruction()' end end
  class Comment; def node_test; 'comment()' end end
  class BogusETag; def node_test; 'bogus-etag()' end end
  class Text; def node_test; 'text()' end end

  # filter_with_path
  class Doc
    def filter_with_path(&block)
      children = []
      self.each_with_path('') {|c, path|
        if yield c, path
          if Elem === c
            children << c.filter_with_path(path, &block)
          else
            children << c
          end
        end
      }
      Doc.new(children)
    end
  end

  class Elem
    def filter_with_path(path, &block)
      return self if self.empty_element?
      children = []
      self.each_with_path(path) {|c, child_path|
        if yield c, child_path
          if Elem === c
            children << c.filter_with_path(child_path, &block)
          else
            children << c
          end
        end
      }
      Elem.new!(@stag, children, @etag)
    end
  end

  # traverse_with_path
  class Doc
    def traverse_with_path(&block)
      yield self, '/'
      self.each_with_path('') {|c, path|
        c.traverse_with_path(path, &block)
      }
    end
  end

  class Elem
    def traverse_with_path(path, &block)
      yield self, path
      self.each_with_path(path) {|c, child_path|
        c.traverse_with_path(child_path, &block)
      }
    end
  end

  module Leaf
    def traverse_with_path(path)
      yield self, path
    end
  end

  # misc
  module Container
    def find_element(*names)
      traverse_element(*names) {|e| return e }
      nil
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
