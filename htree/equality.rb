require 'htree/container'
require 'htree/leaf'
require 'htree/tag'
require 'htree/raw_string'

module HTree
  def hash
    if defined? @hash
      @hash
    else
      @hash = do_hash
    end
  end

  def do_hash
    raise NotImplementedError
  end

  def ==
    raise NotImplementedError
  end

  def eql?(other)
    self == other
  end

  class Container
    def do_hash
      result = 0
      @children.each {|n| result ^= n.hash } if @children
      result
    end

    def ==(other)
      other.class == self.class &&
      @children == other.children
    end

    def ===(other)
      other.class == self.class &&
      @children.length == other.children.length &&
      (0...@children.length).all? {|i| @children[i] === other.children[i] }
    end
  end

  class Elem < Container
    def do_hash
      @stag.hash ^ super ^ @etag.hash
    end

    def ==(other)
      other.class == Elem &&
      @stag == other.stag &&
      @etag == other.etag &&
      @children == other.children
    end

    def ===(other)
      other.class == Elem &&
      @stag === other.stag &&
      (@children && @children.length) == (other.children && other.children.length) &&
      (!@children || (0...@children.length).all? {|i| @children[i] === other.children[i] })
    end

  end

  class Leaf
    def do_hash
      self.raw_string.hash
    end

    def equal_raw_string(other)
      self.raw_string == other.raw_string
    end
  end

  class STag < Markup
    def do_hash
      super ^
      @qualified_name.hash ^
      @attributes.sort.hash ^
      @inherited_namespaces.map {|k,v| [k||"",v]}.sort.hash
    end

    def ==(other)
      other.class == STag &&
      equal_raw_string(other) &&
      @qualified_name == other.qualified_name &&
      @universal_name == other.universal_name &&
      @attributes.sort == other.attributes.sort &&
      @inherited_namespaces.map {|k,v| [k||"",v]}.sort ==
      other.inherited_namespaces.map {|k,v| [k||"",v]}.sort
    end

    def ===(other)
      unless other.class == STag &&
             @universal_name == other.universal_name
        return false
      end

      attrs = {}
      self.each_attribute_text {|uname, text| attrs[uname] = text }
      other.each_attribute_text {|uname, text|
        return false unless attrs[uname] === text
        attrs.delete uname
      }
      attrs.empty?
    end

  end

  class ETag < Markup
    def do_hash
      super ^ @qualified_name.hash
    end

    def ==(other)
      other.class == ETag &&
      equal_raw_string(other) &&
      @qualified_name == other.qualified_name
    end
  end

  class Text < Leaf
    def do_hash
      super ^ @rcdata.hash
    end

    def ==(other)
      other.class == Text &&
      equal_raw_string(other) &&
      @rcdata == other.rcdata
    end

    def ===(other)
      other.class == Text &&
      @rcdata == other.rcdata #xxx: should normalize
    end

  end

  class XMLDecl < Markup
    def do_hash
      super ^ @version.hash ^ @encoding.hash ^ @standalone.hash
    end

    def ==(other)
      other.class == XMLDecl &&
      equal_raw_string(other) &&
      @encoding == other.encoding &&
      @standalone == other.standalone
    end

    def ===(other)
      other.class == XMLDecl &&
      @encoding == other.encoding &&
      @standalone == other.standalone
    end
  end

  class DocType < Markup
    def do_hash
      super ^
      @root_element_name.hash ^
      @system_identifier.hash ^
      @public_identifier.hash
    end

    def ==(other)
      other.class == DocType &&
      equal_raw_string(other) &&
      @root_element_name == other.root_element_name &&
      @system_identifier == other.system_identifier &&
      @public_identifier == other.public_identifier
    end

    def ===(other)
      other.class == DocType &&
      @root_element_name == other.root_element_name &&
      @system_identifier == other.system_identifier &&
      @public_identifier == other.public_identifier
    end
  end

  class ProcIns < Markup
    def do_hash
      super ^
      @target.hash ^
      @content.hash
    end

    def ==(other)
      other.class == ProcIns &&
      equal_raw_string(other) &&
      @target == other.target &&
      @content == other.content
    end

    def ===(other)
      other.class == ProcIns &&
      @target == other.target &&
      @content == other.content
    end
  end

  class Comment < Markup
    def do_hash
      super ^ @content.hash
    end

    def ==(other)
      other.class == Comment &&
      equal_raw_string(other) &&
      @content == other.content
    end

    def ===(other)
      other.class == Comment &&
      @content == other.content
    end

  end
end
