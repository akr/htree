require 'htree/tag'
require 'htree/container'

module HTree
  DefaultNamespace = {"xml"=>"http://www.w3.org/XML/1998/namespace"}

  class Doc
    def update_xmlns(inherited_namespaces=DefaultNamespace)
      Doc.new(@children.map {|c| c.update_xmlns(inherited_namespaces) })
    end
  end

  class STag
    def update_xmlns(inherited)
      used = {}
      [@name, *@attributes.map {|n, v| n }].each {|n|
        next if n.xmlns?
        if n.namespace_uri
          if used.include?(n.namespace_prefix)
            if used[n.namespace_prefix] != n.namespace_uri
              raise STag::Error, "inconsistent namespace: #{n.namespace_prefix.inspect}"
            end
          else
            used[n.namespace_prefix] = n.namespace_uri
          end
        end
      }

      attributes = []
      @attributes.each {|n, v|
        if n.xmlns?
          prefix = n.local_name
          if used.include?(prefix)
            if used[prefix] != inherited[prefix]
              attributes << [n, Text.new(used[prefix])]
            end
            used.delete prefix
          else
            uri = v.to_s
            uri = nil if uri.empty?
            if uri != inherited[prefix]
              attributes << [n, v]
            end
          end
        else
          attributes << [n, v]
        end
      }
      used.each {|prefix, uri|
        if uri != inherited[prefix]
          attributes << [Name.new('xmlns', nil, prefix), Text.new(uri || '')]
        end
      }

      STag.new(@name, attributes, inherited)
    end
  end

  class Elem
    def update_xmlns(inherited_namespaces=DefaultNamespace)
      stag = @stag.update_xmlns(inherited_namespaces)
      Elem.new!(stag, @empty ? nil : @children.map {|c| c.update_xmlns(stag.namespaces) })
    end
  end

  module Leaf
    def update_xmlns(inherited_namespaces=DefaultNamespace)
      self
    end

    def to_xml
      update_xmlns.generate_xml
    end
  end

  module Container
    def to_xml
      update_xmlns.generate_xml
    end
  end
end
