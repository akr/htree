require 'htree/tag'
require 'htree/container'
require 'htree/context'

module HTree
  class Doc
    def update_xmlns(inherited_context=DefaultContext)
      Doc.new(@children.map {|c| c.update_xmlns(inherited_context) })
    end
  end

  class STag
    def update_xmlns(inherited_context)
      # xxx: should be validated in STag#initialize.
      used = {}
      [@name, *@attributes.map {|n, v| n }].each {|n|
        next if n.xmlns?
        if n.namespace_uri
          if used.include?(n.namespace_prefix)
            if used[n.namespace_prefix] != n.namespace_uri
              raise HTree::Error, "inconsistent namespace: #{n.namespace_prefix.inspect}"
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
            if used[prefix] != inherited_context.namespace_uri(prefix)
              attributes << [n, Text.new(used[prefix])]
            end
            used.delete prefix
          else
            uri = v.to_s
            uri = nil if uri.empty?
            if uri != inherited_context.namespace_uri(prefix)
              attributes << [n, v]
            end
          end
        else
          attributes << [n, v]
        end
      }
      used.each {|prefix, uri|
        if uri != inherited_context.namespace_uri(prefix)
          attributes << [Name.new('xmlns', nil, prefix), Text.new(uri || '')]
        end
      }

      STag.new(@name, attributes, inherited_context)
    end
  end

  class Elem
    def update_xmlns(inherited_context=DefaultContext)
      stag = @stag.update_xmlns(inherited_context)
      Elem.new!(stag, @empty ? nil : @children.map {|c| c.update_xmlns(stag.context) })
    end
  end

  module Leaf
    def update_xmlns(inherited_context=DefaultContext)
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
