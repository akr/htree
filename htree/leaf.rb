require 'htree/nodehier'

module HTree
  class XMLDecl < Markup
    def initialize(version, encoding=nil, standalone=nil)
      if /\A[a-zA-Z0-9_.:-]+\z/ !~ version
        raise XMLDecl::Error, "invalid version in XML declaration: #{version.inspect}"
      end
      if encoding && /\A[A-Za-z][A-Za-z0-9._-]*\z/ !~ encoding
        raise XMLDecl::Error, "invalid encoding in XML declaration: #{encoding.inspect}"
      end
      unless standalone == nil || standalone == true || standalone == false
        raise XMLDecl::Error, "invalid standalone document declaration in XML declaration: #{standalone.inspect}"
      end
      @version = version
      @encoding = encoding
      @standalone = standalone
    end
    attr_reader :version, :encoding, :standalone

    def to_xml
      result = "<?xml version=\"#{@version}\""
      if @encoding
        result << " encoding=\"#{@encoding}\""
      end
      if @standalone != nil
        result << " standalone=\"#{@standalone ? 'yes' : 'no'}\""
      end
      result
    end
  end

  class DocType < Markup
    def initialize(root_element_name, public_identifier=nil, system_identifier=nil)
      if public_identifier && /\A[ \x0d\x0aa-zA-Z0-9\-'()+,.\/:=?;!*\#@$_%]*\z/ !~ public_identifier
        raise DocType::Error, "invalid public identifier in document type declaration: #{public_identifier.inspect}"
      end
      if system_identifier && /"/ =~ system_identifier && /'/ =~ system_identifier
        raise DocType::Error, "invalid system identifier in document type declaration: #{system_identifier.inspect}"
      end

      @root_element_name = root_element_name
      @public_identifier = public_identifier
      @system_identifier = system_identifier
    end
    attr_reader :root_element_name, :public_identifier, :system_identifier

    def to_xml
      result = "<!DOCTYPE #{@root_element_name}"
      if public_identifier
        result << "PUBLIC \"#{@public_identifier}\""
      else
        result << "SYSTEM"
      end
      # Although a system identifier is not omissible in XML,
      # we cannot output it if it is not given.
      if system_identifier
        if /"/ !~ system_identifier
          result << " \"#{@system_identifier}\""
        else
          result << " '#{@system_identifier}'"
        end
      end
      result
    end
  end

  class ProcIns < Markup
    class << self
      alias new! new
    end

    def ProcIns.new(target, content)
      content = content.gsub(/\?>/, '? >')
      new! target, content
    end

    def initialize(target, content)
      if /\?>/ =~ content
        raise ProcIns::Error, "invalid processing instruction content: #{content.inspect}"
      end
      @target = target
      @content = content
    end
    attr_reader :target, :content

    def to_xml
      "<?#{@target} #{@content}?>"
    end
  end

  class Comment < Markup
    class << self
      alias new! new
    end

    def Comment.new(content)
      content = content.gsub(/-(-+)/) { '-' + ' -' * $1.length }.sub(/-\z/, '- ')
      new! content
    end

    def initialize(content)
      if /--/ =~ content || /-\z/ =~ content
        raise Comment::Error, "invalid comment content: #{content.inspect}"
      end
      @content = content
    end
    attr_reader :content

    def to_xml
      "<!--#{@content}-->"
    end
  end
end
