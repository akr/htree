require 'pp'
require 'htree/container'
require 'htree/leaf'
require 'htree/tag'
require 'htree/raw_string'

module HTree
  class Doc
    def pretty_print(pp)
      pp.object_group(self) { @children.each {|elt| pp.breakable; pp.pp elt } }
    end
    alias inspect pretty_print_inspect
  end

  class Elem
    def pretty_print(pp)
      if @children
        pp.group(1, "{elem", "}") {
          pp.breakable; pp.pp @stag
          @children.each {|elt| pp.breakable; pp.pp elt }
          if @etag
            pp.breakable; pp.pp @etag
          end
        }
      else
        pp.group(1, '{emptyelem', '}') {
          pp.breakable; pp.pp @stag
        }
      end
    end
    alias inspect pretty_print_inspect
  end

  module Leaf
    def pretty_print(pp)
      pp.group(1, '{', '}') {
        pp.text self.class.name.sub(/.*::/,'').downcase
        if rs = self.raw_string
          rs.each_line {|line|
            pp.breakable
            pp.pp line
          }
        elsif self.respond_to? :generate_xml
          pp.breakable
          pp.text generate_xml
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
    def pretty_print(pp)
      pp.group(1, '<', '>') {
        pp.text @name.inspect

        @attributes.each {|n, t|
          pp.breakable
          pp.text "#{n.inspect}=#{t.generate_xml_attvalue}"
        }
      }
    end
  end

  class ETag
    def pretty_print(pp)
      pp.group(1, '</', '>') {
        pp.text @qualified_name
      }
    end
  end
end
