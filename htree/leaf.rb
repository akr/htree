require 'htree/nodehier'
require 'htree/raw_string'

module HTree
  class XMLDecl
    def initialize(version, encoding=nil, standalone=nil)
      init_raw_string
      if /\A[a-zA-Z0-9_.:-]+\z/ !~ version
        raise HTree::Error, "invalid version in XML declaration: #{version.inspect}"
      end
      if encoding && /\A[A-Za-z][A-Za-z0-9._-]*\z/ !~ encoding
        raise HTree::Error, "invalid encoding in XML declaration: #{encoding.inspect}"
      end
      unless standalone == nil || standalone == true || standalone == false
        raise HTree::Error, "invalid standalone document declaration in XML declaration: #{standalone.inspect}"
      end
      @version = version
      @encoding = encoding
      @standalone = standalone
    end
    attr_reader :version, :encoding, :standalone

    def generate_prolog_xmldecl_xml(out='')
      out << "<?xml version=\"#{@version}\""
      if @encoding
        out << " encoding=\"#{@encoding}\""
      end
      if @standalone != nil
        out << " standalone=\"#{@standalone ? 'yes' : 'no'}\""
      end
      out << "?>"
      out
    end

    def generate_xml(out='')
      out
    end
  end

  class DocType
    def initialize(root_element_name, public_identifier=nil, system_identifier=nil)
      init_raw_string
      if public_identifier && /\A[ \x0d\x0aa-zA-Z0-9\-'()+,.\/:=?;!*\#@$_%]*\z/ !~ public_identifier
        raise HTree::Error, "invalid public identifier in document type declaration: #{public_identifier.inspect}"
      end
      if system_identifier && /"/ =~ system_identifier && /'/ =~ system_identifier
        raise HTree::Error, "invalid system identifier in document type declaration: #{system_identifier.inspect}"
      end

      @root_element_name = root_element_name
      @public_identifier = public_identifier
      @system_identifier = system_identifier
    end
    attr_reader :root_element_name, :public_identifier, :system_identifier

    def generate_prolog_doctypedecl_xml(out='')
      out << "<!DOCTYPE #{@root_element_name}"
      if @public_identifier
        out << " PUBLIC \"#{@public_identifier}\""
      else
        out << " SYSTEM"
      end
      # Although a system identifier is not omissible in XML,
      # we cannot output it if it is not given.
      if @system_identifier
        if /"/ !~ @system_identifier
          out << " \"#{@system_identifier}\""
        else
          out << " '#{@system_identifier}'"
        end
      end
      out << ">"
      out
    end

    def generate_xml(out='')
      out
    end
  end

  class ProcIns
    class << self
      alias new! new
    end

    def ProcIns.new(target, content)
      content = content.gsub(/\?>/, '? >') if content
      new! target, content
    end

    def initialize(target, content)
      init_raw_string
      if content && /\?>/ =~ content
        raise HTree::Error, "invalid processing instruction content: #{content.inspect}"
      end
      @target = target
      @content = content
    end
    attr_reader :target, :content

    def generate_xml(out='')
      out << "<?#{@target}"
      out << " #{@content}" if @content
      out << "?>"
      out
    end
  end

  class Comment
    class << self
      alias new! new
    end

    def Comment.new(content)
      content = content.gsub(/-(-+)/) { '-' + ' -' * $1.length }.sub(/-\z/, '- ')
      new! content
    end

    def initialize(content)
      init_raw_string
      if /--/ =~ content || /-\z/ =~ content
        raise HTree::Error, "invalid comment content: #{content.inspect}"
      end
      @content = content
    end
    attr_reader :content

    def generate_xml(out='')
      out << "<!--#{@content}-->"
      out
    end
  end
end
