require 'htree/nodehier'

module HTree
  class Doc
    def raw_string
      @children.map {|n| n.raw_string }.join('')
    end
  end

  class Elem
    def raw_string
      result = @stag.raw_string.dup
      @children.each {|n| result << n.raw_string }
      result << @etag.raw_string if @etag
      result
    end
  end

  module Leaf
    def init_raw_string
      @raw_string = nil
    end

    def raw_string=(arg)
      @raw_string = arg.dup.freeze
    end

    def raw_string
      @raw_string || self.generate_xml
    end
  end

  # eliminate_raw_string
  class Doc
    def eliminate_raw_string
      Doc.new(@children.map {|c| c.eliminate_raw_string })
    end
  end

  class Elem
    def eliminate_raw_string
      Elem.new!(
        @stag.eliminate_raw_string,
        @empty ? nil : @children.map {|c| c.eliminate_raw_string },
        @etag && @etag.eliminate_raw_string)
    end
  end

  class Text
    def eliminate_raw_string
      Text.new!(@rcdata)
    end
  end

  class STag
    def eliminate_raw_string
      STag.new(@qualified_name, @attributes, @inherited_context)
    end
  end

  class ETag
    def eliminate_raw_string
      self.class.new(@qualified_name)
    end
  end

  class XMLDecl
    def eliminate_raw_string
      XMLDecl.new(@version, @encoding, @standalone)
    end
  end

  class DocType
    def eliminate_raw_string
      DocType.new(@root_element_name, @public_identifier, @system_identifier)
    end
  end

  class ProcIns
    def eliminate_raw_string
      ProcIns.new(@target, @content)
    end
  end

  class Comment
    def eliminate_raw_string
      Comment.new(@content)
    end
  end

end
