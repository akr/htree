require 'htree/encoder'
require 'htree/doc'
require 'htree/elem'
require 'htree/leaf'
require 'htree/text'

module HTree
  class Text
    ChRef = {
      '>' => '&gt;',
      '<' => '&lt;',
      '"' => '&quot;',
    }

    def generate(out, context)
      out.output_text @rcdata.gsub(/[<>]/) {|s| ChRef[s] }
    end

    def to_attvalue
      "\"#{@rcdata.gsub(/[<>"]/) {|s| ChRef[s] }}\""
    end

    def generate_attvalue(out, context)
      out.output_text to_attvalue
    end
  end

  class Name
    def generate(out, context)
      # xxx: validate namespace prefix
      if xmlns?
        if @local_name
          out.output_string "xmlns:#{@local_name}"
        else
          out.output_string "xmlns"
        end
      else
        out.output_string qualified_name
      end
    end

    def generate_attribute(text, out, context)
      generate(out, context)
      out.output_string '='
      text.generate_attvalue(out, context)
    end
  end

  class Doc
    def generate(out, context)
      xmldecl = false
      doctypedecl = false
      @children.each {|n|
        if n.respond_to? :generate_prolog_xmldecl
          n.generate_prolog_xmldecl(out, context) unless xmldecl
          xmldecl = true
        elsif n.respond_to? :generate_prolog_doctypedecl
          n.generate_prolog_doctypedecl(out, context) unless doctypedecl
          doctypedecl = true
        else
          n.generate(out, context)
        end
      }
    end
  end

  class Elem
    def generate(out, context)
      if @empty
        @stag.generate_emptytag(out, context)
      else
        children_context = @stag.generate_stag(out, context)
        @children.each {|n| n.generate(out, children_context) }
        @stag.generate_etag(out, context)
      end
    end
  end

  class STag
    def generate_attributes(out, context)
      @attributes.each {|aname, text|
        next if aname.xmlns?
        out.output_string ' '
        aname.generate_attribute(text, out, context)
      }
      @context.generate_namespaces(out, context)
    end

    def generate_emptytag(out, context)
      out.output_string '<'
      @name.generate(out, context)
      children_context = generate_attributes(out, context)
      out.output_string ' />'
      children_context
    end

    def generate_stag(out, context)
      out.output_string '<'
      @name.generate(out, context)
      children_context = generate_attributes(out, context)
      out.output_string '>'
      children_context
    end

    def generate_etag(out, context)
      out.output_string '</'
      @name.generate(out, context)
      out.output_string '>'
    end
  end

  class Context
    def generate_namespaces(out, context)
      @namespaces.each {|prefix, uri|
        if context.namespace_uri(prefix) != uri
          if prefix
            out.output_string " xmlns:#{prefix}="
          else
            out.output_string " xmlns="
          end
          Text.new(uri).generate_attvalue(out, context)
        end
      }
      context.subst_namespaces(@namespaces)
    end
  end

  class BogusETag
    # don't generate anything.
    def generate(out, context)
    end
  end

  class XMLDecl
    # don't generate anything.
    def generate(out, context)
    end

    def generate_prolog_xmldecl(out, context)
      out.output_string "<?xml version=\"#{@version}\""
      if @encoding
        out.output_string " encoding=\"#{@encoding}\""
      end
      if @standalone != nil
        out.output_string " standalone=\"#{@standalone ? 'yes' : 'no'}\""
      end
      out.output_string "?>"
    end
  end

  class DocType
    # don't generate anything.
    def generate(out, context)
    end

    def generate_prolog_doctypedecl(out, context)
      out.output_string "<!DOCTYPE #{@root_element_name}"
      if @public_identifier
        out.output_string " PUBLIC \"#{@public_identifier}\""
      else
        out.output_string " SYSTEM"
      end
      # Although a system identifier is not omissible in XML,
      # we cannot output it if it is not given.
      if @system_identifier
        if /"/ !~ @system_identifier
          out.output_string " \"#{@system_identifier}\""
        else
          out.output_string " '#{@system_identifier}'"
        end
      end
      out.output_string ">"
    end
  end

  class ProcIns
    def generate(out, context)
      out.output_string "<?#{@target}"
      out.output_string " #{@content}" if @content
      out.output_string "?>"
    end
  end

  class Comment
    def generate(out, context)
      out.output_string "<!--#{@content}-->"
    end
  end
end
