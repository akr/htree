require 'htree/htmlinfo'
require 'htree/regexp-util'
require 'htree/fstr'

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

    QuotedAttr_C = /(#{Name})\s*=\s*(?:"([^"]*)"|'([^']*)')/
    QuotedAttr = QuotedAttr_C.disable_capture
    ValidAttr_C = /(#{Name})\s*=\s*(?:"([^"]*)"|'([^']*)'|(#{NameChar}*))|(#{Nmtoken})/
    ValidAttr = ValidAttr_C.disable_capture
    InvalidAttr1_C = /(#{Name})\s*=\s*(?:'([^'<>]*)'|"([^"<>]*)"|([^\s<>"']*(?![^\s<>"'])))|(#{Nmtoken})/
    InvalidAttr1 = InvalidAttr1_C.disable_capture
    InvalidAttr1End_C =   /(#{Name})(?:\s*=\s*(?:'([^'<>]*)|"([^"<>]*)))/
    InvalidAttr1End = InvalidAttr1End_C.disable_capture

    QuotedStartTag_C = /<(#{Name})((?:\s+#{QuotedAttr})*)\s*>/
    QuotedStartTag = QuotedStartTag_C.disable_capture
    ValidStartTag_C = /<(#{Name})((?:\s+#{ValidAttr})*)\s*>/
    ValidStartTag = ValidStartTag_C.disable_capture
    InvalidStartTag_C = /<(#{Name})((?:(?:\b|\s+)#{InvalidAttr1})*)((?:\b|\s+)#{InvalidAttr1End})?\s*>/
    InvalidStartTag = InvalidStartTag_C.disable_capture
    StartTag = /#{QuotedStartTag}|#{ValidStartTag}|#{InvalidStartTag}/

    QuotedEmptyTag_C = %r{<(#{Name})((?:\s+#{QuotedAttr})*)\s*/>}
    QuotedEmptyTag = QuotedEmptyTag_C.disable_capture
    ValidEmptyTag_C = %r{<(#{Name})((?:\s+#{ValidAttr})*)\s*/>}
    ValidEmptyTag = ValidEmptyTag_C.disable_capture
    InvalidEmptyTag_C = %r{<(#{Name})((?:(?:\b|\s+)#{InvalidAttr1})*)((?:\b|\s+)#{InvalidAttr1End})?\s*/>}
    InvalidEmptyTag = InvalidEmptyTag_C.disable_capture
    EmptyTag = /#{QuotedEmptyTag}|#{ValidEmptyTag}|#{InvalidEmptyTag}/

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
    cdata_content_string = nil
    pcdata = ''
    first_element = true
    index_otherstring = 1
    index_str = 2
    index_xmldecl = 3
    index_doctype = 4
    index_xmlprocins = 5
    index_quotedstarttag = 6
    index_quotedemptytag = 7
    index_starttag = 8
    index_endtag = 9
    index_emptytag = 10
    index_comment = 11
    index_cdata = 12
    index_end = 13
    pat = /\G(.*?)((#{Pat::XmlDecl})
                  |(#{Pat::DocType})
                  |(#{Pat::XmlProcIns})
                  |(#{Pat::QuotedStartTag})
                  |(#{Pat::QuotedEmptyTag})
                  |(#{Pat::StartTag})
                  |(#{Pat::EndTag})
                  |(#{Pat::EmptyTag})
                  |(#{Pat::Comment})
                  |(#{Pat::CDATA})
                  |(\z))
          /oxm
    input.scan(pat) {
      match = $~
      if cdata_content
        cdata_content_string << match[index_otherstring]
        str = match[index_str]
        if match[index_endtag] && str[Pat::Name] == cdata_content
          unless cdata_content_string.empty?
            yield [:text_cdata_content, HTree.frozen_string(cdata_content_string)]
          end
          yield [:etag, HTree.frozen_string(str)]
          cdata_content = nil
          cdata_content_string = nil
        elsif match[index_end]
          cdata_content_string << str
          unless cdata_content_string.empty?
            yield [:text_cdata_content, HTree.frozen_string(cdata_content_string)]
          end
          cdata_content = nil
          cdata_content_string = nil
        else
          cdata_content_string << str
        end
      else
        pcdata << match[index_otherstring]
        str = match[index_str]
        if !pcdata.empty?
          yield [:text_pcdata, HTree.frozen_string(pcdata)]
          pcdata = ''
        end
        if match[index_xmldecl]
          yield [:xmldecl, HTree.frozen_string(str)]
          is_xml = true
        elsif match[index_doctype]
          Pat::DocType_C =~ str
          root_element_name = $1
          public_identifier = $2 || $3
          #system_identifier = $4 || $5
          is_html = true if /\Ahtml\z/i =~ root_element_name
          is_xml = true if public_identifier && %r{\A-//W3C//DTD XHTML } =~ public_identifier
          yield [:doctype, HTree.frozen_string(str)]
        elsif match[index_xmlprocins]
          yield [:procins, HTree.frozen_string(str)]
        elsif match[index_starttag] || match[index_quotedstarttag]
          yield stag = [:stag, HTree.frozen_string(str)]
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
            cdata_content_string = ''
          end
        elsif match[index_endtag]
          yield [:etag, HTree.frozen_string(str)]
        elsif match[index_emptytag] || match[index_quotedemptytag]
          yield [:emptytag, HTree.frozen_string(str)]
          first_element = false
          #is_xml = true
        elsif match[index_comment]
          yield [:comment, HTree.frozen_string(str)]
        elsif match[index_cdata]
          yield [:text_cdata_section, HTree.frozen_string(str)]
        elsif match[index_end]
          # pass
        else
          raise Exception, "unknown match [bug]"
        end
      end
    }
    return is_xml, is_html
  end
  # :startdoc:
end
