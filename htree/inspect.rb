require 'pp'
require 'htree/container'
require 'htree/leaf'
require 'htree/tag'
require 'htree/raw_string'

module HTree
  class Doc
    def pretty_print(q)
      q.object_group(self) { @children.each {|elt| q.breakable; q.pp elt } }
    end
    alias inspect pretty_print_inspect
  end

  class Elem
    def pretty_print(q)
      if @empty
        q.group(1, '{emptyelem', '}') {
          q.breakable; q.pp @stag
        }
      else
        q.group(1, "{elem", "}") {
          q.breakable; q.pp @stag
          @children.each {|elt| q.breakable; q.pp elt }
          if @etag
            q.breakable; q.pp @etag
          end
        }
      end
    end
    alias inspect pretty_print_inspect
  end

  module Leaf
    def pretty_print(q)
      q.group(1, '{', '}') {
        q.text self.class.name.sub(/.*::/,'').downcase
        if rs = @raw_string
          rs.scan(/[^\r\n]*(?:\r\n?|\n|[^\r\n]\z)/) {|line|
            q.breakable
            q.pp line
          }
        elsif self.respond_to? :to_xml
          q.breakable
          q.text to_xml
        end
      }
    end
    alias inspect pretty_print_inspect
  end

  class Name
    def inspect
      if xmlns?
        @local_name ? "xmlns:#{@local_name}" : "xmlns"
      elsif !@namespace_uri
        @local_name
      elsif @namespace_prefix
        "#{@namespace_prefix}{#{@namespace_uri}}#{@local_name}"
      elsif @namespace_prefix == false
        "-{#{@namespace_uri}}#{@local_name}"
      else
        "{#{@namespace_uri}}#{@local_name}"
      end
    end
  end

  class STag
    def pretty_print(q)
      q.group(1, '<', '>') {
        q.text @name.inspect

        @attributes.each {|n, t|
          q.breakable
          q.text "#{n.inspect}=#{t.to_attvalue}"
        }
      }
    end
  end

  class ETag
    def pretty_print(q)
      q.group(1, '</', '>') {
        q.text @qualified_name
      }
    end
  end

  class BogusETag
    def pretty_print(q)
      q.group(1, '{', '}') {
        q.text self.class.name.sub(/.*::/,'').downcase
        if rs = @raw_string
          q.breakable
          q.text rs
        else
          q.text "</#{@qualified_name}>"
        end
      }
    end
  end
end
