require 'pp'
require 'htree/container'
require 'htree/leaf'
require 'htree/tag'
require 'htree/raw_string'

module HTree
  class Doc < Container
    def pretty_print(pp)
      pp.object_group(self) { @children.each {|elt| pp.breakable; pp.pp elt } }
    end
    alias inspect pretty_print_inspect
  end

  class Elem < Container
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

  class Leaf < Node
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
          pp.text to_xml
        end
      }
    end
    alias inspect pretty_print_inspect
  end

  class STag < Markup
    def pretty_print(pp)
      pp.group(1, '<', '>') {
        if !@namespace_uri
          pp.text @local_name
        elsif @namespace_prefix
          pp.text "#{@namespace_prefix}{#{@namespace_uri}}#{@local_name}"
        elsif @qualified_name
          pp.text "-{#{@namespace_uri}}#{@local_name}"
        else
          pp.text "{#{@namespace_uri}}#{@local_name}"
        end

        each_namespace_attribute {|prefix, uri|
          pp.breakable
          if prefix
            pp.text "xmlns:#{prefix}=#{uri}"
          else
            pp.text "xmlns=#{uri}"
          end
        }

        each_attribute_info {|namespace_uri, prefix, lname, text|
          pp.breakable
          if namespace_uri
            if prefix
              pp.text "#{prefix}{#{namespace_uri}}"
            else
              pp.text "{#{namespace_uri}}"
            end
          end
          pp.text "#{lname}=#{text.to_xml_attvalue}"
        }
      }
    end
  end
end
