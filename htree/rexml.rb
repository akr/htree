require 'htree/modules'

module HTree
  module Node
    # convert to REXML tree.
    def to_rexml
      require 'rexml/document'
      to_rexml_internal(DefaultContext)
    end
  end

  # :stopdoc:

  class Doc
    def to_rexml_internal(context)
      result = REXML::Document.new
      self.children.each {|c|
        c = c.to_rexml_internal(context)
        result << c if c
      }
      result
    end
  end

  class Elem
    def to_rexml_internal(context)
      ename = self.element_name
      ns_decl = {}
      if context.namespace_uri(ename.namespace_prefix) != ename.namespace_uri
        ns_decl[ename.namespace_prefix] = ename.namespace_uri
      end

      if ename.namespace_prefix
        result = REXML::Element.new("#{ename.namespace_prefix}:#{ename.local_name}")
      else
        result = REXML::Element.new(ename.local_name)
      end

      self.each_attribute {|aname, atext|
        if aname.namespace_prefix
          if context.namespace_uri(aname.namespace_prefix) != aname.namespace_uri
            ns_decl[aname.namespace_prefix] = aname.namespace_uri
          end
          result.add_attribute("#{aname.namespace_prefix}:#{name.local_name}", atext.to_s)
        else
          result.add_attribute(aname.local_name, atext.to_s)
        end
      }

      ns_decl.each {|k, v|
        if k
          result.add_namespace(k, v)
        else
          result.add_namespace(v)
        end
      }
      context = context.subst_namespaces(ns_decl)

      self.children.each {|c|
        c = c.to_rexml_internal(context)
        result << c if c
      }
      result
    end
  end

  class Text
    def to_rexml_internal(context)
      REXML::Text.new(self.rcdata, true, nil, true)
    end
  end

  class XMLDecl
    def to_rexml_internal(context)
      REXML::XMLDecl.new(self.version, self.encoding, self.standalone)
    end
  end

  class DocType
    def to_rexml_internal(context)
      REXML::DocType.new(self.root_element_name, self.generate_content)
    end
  end

  class ProcIns
    def to_rexml_internal(context)
      REXML::Instruction.new(self.target, self.content)
    end
  end

  class Comment
    def to_rexml_internal(context)
      REXML::Comment.new(self.content)
    end
  end

  class BogusETag
    def to_rexml_internal(context)
      nil
    end
  end

  # :startdoc:
end
