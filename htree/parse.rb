require 'htree/scan'
require 'htree/htmlinfo'
require 'htree/text'
require 'htree/tag'
require 'htree/leaf'
require 'htree/container'
require 'htree/raw_string'
require 'htree/context'

module HTree
  # HTree.parse returns parses <i>input</i> and return a document tree.
  # represented by HTree::Doc.
  #
  # <i>input</i> should be a String or
  # an object which respond to read or open method.
  # For example, IO, StringIO, Pathname, URI::HTTP and URI::FTP is acceptable.
  # Note that last URIs need open-uri to open.
  #
  # If opened file or read content has charset method,
  # HTree.parse decode it according to $KCODE before parsing.
  # Otherwise HTree.parse assumes the character encoding of the content is
  # same as $KCODE.
  # Note that the charste method is provided by URI::HTTP with open-uri.
  def HTree.parse(input)
    parse_as(input, HTMLContext, false)
  end

  # HTree.parse_xml returns parses <i>input</i> and return a tree.
  #
  # It behaves almost same as HTree.parse but it assumes <i>input</> is XML
  # even if no XML declaration.
  # The assumption causes following differences.
  # * doesn't downcase element name.
  # * The content of <script> and <style> element is PCDATA, not CDATA.
  # * doesn't assume a default namespace http://www.w3.org/1999/xhtml.
  def HTree.parse_xml(input)
    parse_as(input, DefaultContext, true)
  end

  def HTree.parse_as(input, context, is_xml) # :nodoc:
    input_charset = nil
    if input.respond_to? :read # IO, StringIO
      input = input.read
      input_charset = input.charset if input.respond_to? :charset
    elsif input.respond_to? :open # Pathname, URI with open-uri
      input.open {|f|
        input = f.read
        input_charset = f.charset if f.respond_to? :charset
      }
    end
    if input_charset && input_charset != Encoder.internal_charset
      input = Iconv.conv(Encoder.internal_charset, input_charset, input)
    end

    tokens = []
    scan(input) {|token|
      tokens << token
      is_xml = true if token[0] == :xmldecl
    }
    structure_list = parse_pairs(tokens, is_xml)
    structure_list = fix_structure_list(structure_list, is_xml)
    nodes = structure_list.map {|s| build_node(s, is_xml, context) }
    Doc.new(nodes)
  end

  def HTree.parse_pairs(tokens, is_xml) # :nodoc:
    stack = [[nil, nil, []]]
    tokens.each {|token|
      case token[0]
      when :stag
        stag_raw_string = token[1]
        stagname = stag_raw_string[Pat::Name]
        stagname = stagname.downcase if !is_xml
        stack << [stagname, stag_raw_string, []]
      when :etag
        etag_raw_string = token[1]
        etagname = etag_raw_string[Pat::Name]
        etagname = etagname.downcase if !is_xml
        matched_elem = nil
        stack.reverse_each {|elem|
          stagname, _, _ = elem
          if stagname == etagname
            matched_elem = elem
            break
          end
        }
        if matched_elem
          until matched_elem.equal? stack.last
            stagname, stag_raw_string, children = stack.pop
            stack.last[2] << [:elem, stag_raw_string, children]
          end
          stagname, stag_raw_string, children = stack.pop
          stack.last[2] << [:elem, stag_raw_string, children, etag_raw_string]
        else
          stack.last[2] << [:bogus_etag, etag_raw_string]
        end
      else
        stack.last[2] << token
      end
    }
    elem = nil
    while 1 < stack.length
      stagname, stag_raw_string, children = stack.pop
      stack.last[2] << [:elem, stag_raw_string, children]
    end
    stack[0][2]
  end

  def HTree.fix_structure_list(structure_list, is_xml) # :nodoc:
    result = []
    rest = structure_list.dup
    until rest.empty?
      structure = rest.shift
      if structure[0] == :elem
        elem, rest2 = fix_element(structure, [], [], is_xml)
        result << elem
        rest = rest2 + rest
      else
        result << structure
      end
    end
    result
  end

  def HTree.fix_element(elem, excluded_tags, included_tags, is_xml) # :nodoc:
    stag_raw_string = elem[1]
    children = elem[2]
    if etag_raw_string = elem[3]
      return [:elem, stag_raw_string, fix_structure_list(children, is_xml), etag_raw_string], []
    else
      tagname = stag_raw_string[Pat::Name]
      tagname = tagname.downcase if !is_xml
      if ElementContent[tagname] == :EMPTY
        return [:elem, stag_raw_string, []], children
      else
        if ElementContent[tagname] == :CDATA
          possible_tags = []
        else
          possible_tags = ElementContent[tagname]
        end
        if possible_tags
          excluded_tags2 = ElementExclusions[tagname]
          included_tags2 = ElementInclusions[tagname]
          excluded_tags |= excluded_tags2 if excluded_tags2
          included_tags |= included_tags2 if included_tags2
          containable_tags = (possible_tags | included_tags) - excluded_tags
          uncontainable_tags = ElementContent.keys - containable_tags
        else
          # If the tagname is unknown, it is assumed that any element
          # except excluded can be contained.
          uncontainable_tags = excluded_tags
        end
        fixed_children = []
        rest = children
        until rest.empty?
          if rest[0][0] == :elem
            elem = rest.shift
            elem_tagname = elem[1][Pat::Name]
            elem_tagname = elem_tagname.downcase if !is_xml
            if uncontainable_tags.include? elem_tagname
              rest.unshift elem
              break
            else
              fixed_elem, rest2 = fix_element(elem, excluded_tags, included_tags, is_xml)
              fixed_children << fixed_elem
              rest = rest2 + rest
            end
          else
            fixed_children << rest.shift
          end
        end
        return [:elem, stag_raw_string, fixed_children], rest
      end
    end
  end

  def HTree.build_node(structure, is_xml, inherited_context=DefaultContext) # :nodoc:
    case structure[0]
    when :elem
      _, stag_rawstring, children, etag_rawstring = structure
      etag = etag_rawstring && ETag.parse(etag_rawstring, is_xml)
      stag = STag.parse(stag_rawstring, is_xml, inherited_context)
      if !children.empty? || etag
        Elem.new!(stag,
                  children.map {|c| build_node(c, is_xml, stag.context) },
                  etag)
      else
        Elem.new!(stag)
      end
    when :emptytag
      Elem.new!(STag.parse(structure[1], is_xml, inherited_context))
    when :bogus_etag
      BogusETag.parse(structure[1])
    when :xmldecl
      XMLDecl.parse(structure[1])
    when :doctype
      DocType.parse(structure[1], is_xml)
    when :procins
      ProcIns.parse(structure[1])
    when :comment
      Comment.parse(structure[1])
    when :text_pcdata
      Text.parse_pcdata(structure[1])
    when :text_cdata_content
      Text.parse_cdata_content(structure[1])
    when :text_cdata_section
      Text.parse_cdata_section(structure[1])
    else
      raise Exception, "[bug] unknown structure: #{structure.inspect}"
    end
  end

  class STag
    def STag.parse(raw_string, case_sensitive=false, inherited_context=DefaultContext) # :nodoc:
      if /\A#{Pat::StartTag}\z/o =~ raw_string
        is_stag = true
      elsif /\A#{Pat::EmptyTag}\z/o =~ raw_string
        is_stag = false
      else
        raise HTree::Error, "cannot recognize as start tag or empty tag: #{raw_string.inspect}"
      end

      attrs = []
      if (is_stag ? /\A#{Pat::ValidStartTag_C}\z/o : /\A#{Pat::ValidEmptyTag_C}\z/o) =~ raw_string
        qname = $1
        $2.scan(Pat::ValidAttr_C) {
          attrs << ($5 ? [nil, $5] : [$1, $2 || $3 || $4])
        }
      elsif (is_stag ? /\A#{Pat::InvalidStartTag_C}\z/o : /\A#{Pat::InvalidEmptyTag_C}\z/o) =~ raw_string
        qname = $1
        last_attr = $3
        $2.scan(Pat::InvalidAttr1_C) {
          attrs << ($5 ? [nil, $5] : [$1, $2 || $3 || $4])
        }
        if last_attr
          /#{Pat::InvalidAttr1End_C}/o =~ last_attr
          attrs << [$1, $2 || $3]
        end
      else
        raise Exception, "[bug] cannot recognize as start tag: #{raw_string.inspect}"
      end

      qname = qname.downcase unless case_sensitive

      attrs.map! {|aname, aval|
        if aname
          aname = case_sensitive ? aname : aname.downcase
          [aname, Text.parse_pcdata(aval)]
        else
          if val2name = OmittedAttrName[qname]
            aval_downcase = aval.downcase
            aname = val2name.fetch(aval_downcase, aval_downcase)
          else
            aname = aval
          end
          [aname, Text.new(aval)]
        end
      }

      result = STag.new(qname, attrs, inherited_context)
      result.raw_string = raw_string
      result
    end
  end

  class ETag
    def ETag.parse(raw_string, case_sensitive=false) # :nodoc:
      unless /\A#{Pat::EndTag_C}\z/o =~ raw_string
        raise HTree::Error, "cannot recognize as end tag: #{raw_string.inspect}"
      end

      qname = $1
      qname = qname.downcase unless case_sensitive

      result = self.new(qname)
      result.raw_string = raw_string
      result
    end
  end

  class Text
    def Text.parse_pcdata(raw_string) # :nodoc:
      fixed = raw_string.gsub(/&(?:(?:#[0-9]+|#x[0-9a-fA-F]+|([A-Za-z][A-Za-z0-9]*));?)?/o) {|s|
        name = $1
        case s
        when /;\z/
          s
        when /\A&#/
          "#{s};"
        when '&'
          '&amp;'
        else 
          if NamedCharactersPattern =~ name
            "&#{name};"
          else
            "&amp;#{name}"
          end
        end
      }
      result = new!(fixed)
      result.raw_string = raw_string
      result
    end

    def Text.parse_cdata_content(raw_string) # :nodoc:
      result = Text.new(raw_string)
      result.raw_string = raw_string
      result
    end

    def Text.parse_cdata_section(raw_string) # :nodoc:
      unless /\A#{Pat::CDATA_C}\z/o =~ raw_string
        raise HTree::Error, "cannot recognize as CDATA section: #{raw_string.inspect}"
      end

      content = $1

      result = Text.new(content)
      result.raw_string = raw_string
      result
    end
  end

  class XMLDecl
    def XMLDecl.parse(raw_string) # :nodoc:
      unless /\A#{Pat::XmlDecl_C}\z/o =~ raw_string
        raise HTree::Error, "cannot recognize as XML declaration: #{raw_string.inspect}"
      end

      version = $1 || $2
      encoding = $3 || $4
      case $5 || $6
      when 'yes'
        standalone = true
      when 'no'
        standalone = false
      else
        standalone = nil
      end

      result = XMLDecl.new(version, encoding, standalone)
      result.raw_string = raw_string
      result
    end
  end

  class DocType
    def DocType.parse(raw_string, is_xml) # :nodoc:
      unless /\A#{Pat::DocType_C}\z/o =~ raw_string
        raise HTree::Error, "cannot recognize as XML declaration: #{raw_string.inspect}"
      end

      root_element_name = $1
      public_identifier = $2 || $3
      system_identifier = $4 || $5

      root_element_name = root_element_name.downcase if !is_xml

      result = DocType.new(root_element_name, public_identifier, system_identifier)
      result.raw_string = raw_string
      result
    end
  end

  class ProcIns
    def ProcIns.parse(raw_string) # :nodoc:
      unless /\A#{Pat::XmlProcIns_C}\z/o =~ raw_string
        raise HTree::Error, "cannot recognize as processing instruction: #{raw_string.inspect}"
      end

      target = $1
      content = $2

      result = ProcIns.new(target, content)
      result.raw_string = raw_string
      result
    end
  end

  class Comment
    def Comment.parse(raw_string) # :nodoc:
      unless /\A#{Pat::Comment_C}\z/o =~ raw_string
        raise HTree::Error, "cannot recognize as comment: #{raw_string.inspect}"
      end

      content = $1

      result = Comment.new(content)
      result.raw_string = raw_string
      result
    end
  end
end
