require 'htree/htmlinfo'
require 'htree/regexp-util'

module HTree
  # :stopdoc:
  module Pat
    NameChar = /[-A-Za-z0-9._:]/
    Name = /[A-Za-z_:]#{NameChar}*/
    Nmtoken = /#{NameChar}+/

    Comment_C = /<!--(.*?)-->/m
    Comment = Comment_C.disable_capture
    CDATA_C = /<!\[CDATA\[(.*?)\]\]>/m
    CDATA = CDATA_C.disable_capture

    ValidAttr_C = /(#{Name})\s*=\s*(?:"([^"]*)"|'([^']*)'|(#{NameChar}*))|(#{Nmtoken})/
    ValidAttr = ValidAttr_C.disable_capture
    InvalidAttr1_C = /(#{Name})\s*=\s*(?:'([^'<>]*)'|"([^"<>]*)"|([^\s<>"']*))|(#{Nmtoken})/
    InvalidAttr1 = InvalidAttr1_C.disable_capture
    InvalidAttr1End_C =   /(#{Name})(?:\s*=\s*(?:'([^'<>]*)|"([^"<>]*)))/
    InvalidAttr1End = InvalidAttr1End_C.disable_capture

    ValidStartTag_C = /<(#{Name})((?:\s+#{ValidAttr})*)\s*>/
    ValidStartTag = ValidStartTag_C.disable_capture
    InvalidStartTag_C = /<(#{Name})((?:(?:\b|\s+)#{InvalidAttr1})*)((?:\b|\s+)#{InvalidAttr1End})?\s*>/
    InvalidStartTag = InvalidStartTag_C.disable_capture
    StartTag = /#{ValidStartTag}|#{InvalidStartTag}/

    ValidEmptyTag_C = %r{<(#{Name})((?:\s+#{ValidAttr})*)\s*/>}
    ValidEmptyTag = ValidEmptyTag_C.disable_capture
    InvalidEmptyTag_C = %r{<(#{Name})((?:(?:\b|\s+)#{InvalidAttr1})*)((?:\b|\s+)#{InvalidAttr1End})?\s*/>}
    InvalidEmptyTag = InvalidEmptyTag_C.disable_capture
    EmptyTag = /#{ValidEmptyTag}|#{InvalidEmptyTag}/

    EndTag_C = %r{</(#{Name})\s*>}
    EndTag = EndTag_C.disable_capture

    XmlVersionNum = /[a-zA-Z0-9_.:-]+/
    XmlVersionInfo_C = /\s+version\s*=\s*(?:'(#{XmlVersionNum})'|"(#{XmlVersionNum})")/
    XmlVersionInfo = XmlVersionInfo_C.disable_capture
    XmlEncName = /[A-Za-z][A-Za-z0-9._-]*/
    XmlEncodingDecl_C = /\s+encoding\s*=\s*(?:"(#{XmlEncName})"|'(#{XmlEncName})')/
    XmlEncodingDecl = XmlEncodingDecl_C.disable_capture
    XmlSDDecl_C = /\s+standalone\s*=\s*(?:'(yes|no)'|"(yes|no)")/
    XmlSDDecl = XmlSDDecl_C.disable_capture
    XmlDecl_C = /<\?xml#{XmlVersionInfo_C}#{XmlEncodingDecl_C}?#{XmlSDDecl_C}?\s*\?>/
    XmlDecl = /<\?xml#{XmlVersionInfo}#{XmlEncodingDecl}?#{XmlSDDecl}?\s*\?>/

    # xxx: internal DTD subset is not recognized: '[' (markupdecl | DeclSep)* ']' S?)?
    SystemLiteral_C = /"([^"]*)"|'([^']*)'/
    PubidLiteral_C = %r{"([\sa-zA-Z0-9\-'()+,./:=?;!*\#@$_%]*)"|'([\sa-zA-Z0-9\-()+,./:=?;!*\#@$_%]*)'}
    ExternalID_C = /(?:SYSTEM|PUBLIC\s+#{PubidLiteral_C})(?:\s+#{SystemLiteral_C})?/
    DocType_C = /<!DOCTYPE\s+(#{Name})(?:\s+#{ExternalID_C})?\s*(?:\[.*?\]\s*)?>/m
    DocType = DocType_C.disable_capture

    XmlProcIns_C = /<\?(#{Name})(?:\s+(.*?))?\?>/m
    XmlProcIns = XmlProcIns_C.disable_capture
    #ProcIns = /<\?([^>]*)>/m
  end

  def HTree.scan(input, is_xml=false)
    is_html = false
    cdata_content = nil
    text_start = 0
    first_element = true
    input.scan(/(#{Pat::XmlDecl})
               |(#{Pat::DocType})
               |(#{Pat::XmlProcIns})
               |(#{Pat::StartTag})
               |(#{Pat::EndTag})
               |(#{Pat::EmptyTag})
               |(#{Pat::Comment})
               |(#{Pat::CDATA})/ox) {
      match = $~
      if cdata_content
        str = $&
        if $5 && str[Pat::Name] == cdata_content
          text_end = match.begin(0)
          if text_start < text_end
            yield [:text_cdata_content, input[text_start...text_end]]
            text_start = match.end(0)
          end
          yield [:etag, str]
          cdata_content = nil
        end
      else
        str = match[0]
        text_end = match.begin(0)
        if text_start < text_end
          yield [:text_pcdata, input[text_start...text_end]]
        end
        text_start = match.end(0)
        if match.begin(1)
          yield [:xmldecl, str]
          is_xml = true
        elsif match.begin(2)
          Pat::DocType_C =~ str
          is_html = true if /\Ahtml\z/i =~ $1 
          yield [:doctype, str]
        elsif match.begin(3)
          yield [:procins, str]
        elsif match.begin(4)
          yield stag = [:stag, str]
          tagname = str[Pat::Name]
          if first_element
            if /\A(?:html|head|title|isindex|base|script|style|meta|link|object)\z/i =~ tagname
              is_html = true
            else
              is_xml = true
            end
            first_element = false
          end
          if !is_xml && ElementContent[tagname] == :CDATA
            cdata_content = tagname
          end
        elsif match.begin(5)
          yield [:etag, str]
        elsif match.begin(6)
          yield [:emptytag, str]
          first_element = false
          #is_xml = true
        elsif match.begin(7)
          yield [:comment, str]
        elsif match.begin(8)
          yield [:text_cdata_section, str]
        else
          raise Exception, "unknown match [bug]"
        end
      end
    }
    text_end = input.length
    if text_start < text_end
      if cdata_content
        yield [:text_cdata_content, input[text_start...text_end]]
      else
        yield [:text_pcdata, input[text_start...text_end]]
      end
    end
    return is_xml, is_html
  end
  # :startdoc:
end
