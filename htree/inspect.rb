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
          pp.breakable; pp.pp @etag
        }
      else
        pp.group(1, '{emptyelem', '}') {
          pp.breakable; pp.pp @stag
        }
      end
    end
    alias inspect pretty_print_inspect
  end

  class Leaf
    def pretty_print(pp)
      pp.group(1, '{', '}') {
        pp.text self.class.name.sub(/.*::/,'').downcase
        if rs = self.raw_string
          rs.each_line {|line|
            pp.breakable
            pp.pp line
          }
        else
          pp.breakable
          pp.text generate_xml # xxx: may raise
        end
      }
    end
    alias inspect pretty_print_inspect
  end

  class Name
    def inspect
      if !@namespace_uri
        @local_name
      elsif @namespace_prefix
        "#{@namespace_prefix}{#{@namespace_uri}}#{@local_name}"
      elsif self.qualified_name
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
          if n.xmlns?
            if n.namespace_prefix
              pp.text "xmlns:#{n.namespace_prefix}=#{t}"
            else
              pp.text "xmlns=#{t}"
            end
          else
            if n.namespace_uri
              if n.namespace_prefix
                pp.text "#{n.namespace_prefix}{#{n.namespace_uri}}"
              else
                pp.text "{#{n.namespace_uri}}"
              end
            end
            pp.text "#{n.local_name}=#{t.generate_xml_attvalue}"
          end
        }
      }
    end
  end

  class ETag
    def pretty_print(pp)
      pp.group(1, '<', '>') {
        pp.text @qualified_name
      }
    end
  end
end
