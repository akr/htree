if !"".respond_to?(:encode)
  require 'iconv'
end

module HTree
  class DummyEncodingConverter
    def initialize(encoding)
      @encoding = encoding
    end

    def primitive_convert(src, dst, destination_buffer=nil, destination_byteoffset=nil, destination_bytesize=nil, opts=nil)
      dst << src
      src.clear
      :source_buffer_empty
    end

    def convert(str)
      str
    end

    def finish
      ""
    end
  end

  class Encoder
    # HTree::Encoder.internal_charset returns the MIME charset corresponding to $KCODE.
    #
    # - 'ISO-8859-1' when $KCODE=='NONE'
    # - 'UTF-8' when $KCODE=='UTF8'
    # - 'EUC-JP' when $KCODE=='EUC'
    # - 'Shift_JIS' when $KCODE=='SJIS'
    #
    # This mapping ignores EUC-KR and various single byte charset other than ISO-8859-1 at least.
    # This should be fixed when Ruby is m17nized.
    def Encoder.internal_charset
      if Object.const_defined? :Encoding
        Encoding.default_external.name
      else
        KcodeCharset[$KCODE]
      end
    end

    def initialize(output_encoding, internal_encoding=HTree::Encoder.internal_charset)
      @buf = ''
      @internal_encoding = internal_encoding
      @output_encoding = output_encoding
      if defined? Encoding::Converter
        if @internal_encoding == output_encoding
          @ic = DummyEncodingConverter.new(@internal_encoding)
        else
          @ic = Encoding::Converter.new(@internal_encoding, output_encoding)
        end
      else
        @ic = Iconv.new(output_encoding, @internal_encoding)
      end
      @charpat = FirstCharPattern[internal_encoding]
      @subcharset_list = SubCharset[output_encoding] || []
      @subcharset_ic = {}
      @subcharset_list.each {|subcharset|
        if defined? Encoding::Converter
          if @internal_encoding == subcharset
            @subcharset_ic[subcharset] = DummyEncodingConverter.new(@internal_encoding)
          else
            @subcharset_ic[subcharset] = Encoding::Converter.new(@internal_encoding, subcharset)
          end
        else
          @subcharset_ic[subcharset] = Iconv.new(subcharset, @internal_encoding)
        end
      }
      @html_output = false
    end

    # :stopdoc:
    def html_output?
      @html_output
    end

    def html_output=(flag)
      @html_output = flag
    end

    def output_cdata_content_do(out, pre, body, post)
      if @html_output
        pre.call
        body.call
        post.call(out)
      else
        body.call
      end
      return out
    end

    def output_slash_if_xml
      if !@html_output
        output_string('/')
      end
    end

    def output_cdata_content(content, context)
      if @html_output
        # xxx: should raise an error for non-text node?
        texts = content.grep(HTree::Text)
        text = HTree::Text.concat(*texts)
        text.output_cdata(self)
      else
        content.each {|n| n.output(self, context) }
      end
    end

    def output_cdata_for_html(*args)
      str = args.join('')
      if %r{</} =~ str
        raise ArgumentError, "cdata contains '</' : #{str.inspect}"
      end
      output_string str
    end

    def output_string(internal_str, external_str=nil)
      if !external_str
        if @ic.respond_to? :convert
          external_str = @ic.convert(internal_str)
        else
          external_str = @ic.iconv(internal_str)
        end
      end
      @buf.force_encoding(external_str.encoding) if @buf.empty? && @buf.respond_to?(:force_encoding) # xxx: should be fixed Ruby itself
      @buf << external_str
      @subcharset_ic.reject! {|subcharset, ic|
        if ic.respond_to? :convert
          begin
            ic.convert(internal_str) != external_str
          rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
            true
          end
        else
          begin
            ic.iconv(internal_str) != external_str
          rescue Iconv::Failure
            true
          end
        end
      }
      nil
    end

    def output_text(string)
      if string.respond_to? :encode
        if string.encoding != Encoding::US_ASCII &&
           string.encoding.to_s != @internal_encoding
          string = string.encode(@internal_encoding)
        end
        #string = string.dup.force_encoding("ASCII-8BIT")
      end
      while true
        if @ic.respond_to? :convert
          if string
            src = string.dup
            res = @ic.primitive_convert(src, dst="", nil, nil, :partial_input => true)
          else
            res = @ic.primitive_convert(nil, dst="")
          end
          case res
          when :invalid_byte_sequence
            success = dst
            failed = src
            _, _, _, error_bytes, _ = @ic.primitive_errinfo
            preconv_bytesize = string.bytesize - failed.bytesize - error_bytes.bytesize
            output_string string[0, preconv_bytesize], success
            string = @ic.putback + failed
            output_string '?'
            next
          when :undefined_conversion
            success = dst
            failed = src
            _, enc1, _, error_bytes, _ = @ic.primitive_errinfo
            preconv_bytesize = string.bytesize - failed.bytesize - error_bytes.bytesize
            output_string string[0, preconv_bytesize], success
            string = @ic.putback + failed
            output_string error_bytes.encode('US-ASCII', enc1, :xml=>:text)
            next
          when :source_buffer_empty, :finished
            output_string string, dst
            return
          else
            raise "unexpected encoding converter result: #{res}"
          end
        else
          begin
            output_string string, @ic.iconv(string)
            return
          rescue Iconv::IllegalSequence, Iconv::InvalidCharacter => e
            success = e.success
            failed = e.failed
          end
          output_string string[0, string.length - failed.length], success
        end
        if FirstCharPattern[@internal_encoding] !~ failed
          # xxx: should be configulable?
          #raise ArgumentError, "cannot extract first character: #{e.failed.dump}"
          string = failed[1, failed.length-1]
          output_string '?'
        else
          char = $&
          rest = $'
          begin
            if char.respond_to? :encode
              excs = [Encoding::UndefinedConversionError,
                      Encoding::InvalidByteSequenceError]
              ucode = char.encode("UTF-8", @internal_encoding).unpack("U")[0]
            else
              excs = [Iconv::IllegalSequence, Iconv::InvalidCharacter]
              ucode = Iconv.conv("UTF-8", @internal_encoding, char).unpack("U")[0]
            end
            char = "&##{ucode};"
          rescue *excs
            # xxx: should be configulable?
            char = '?'
          end
          output_string char
          string = rest
        end
      end
    end

    ChRef = {
      '&' => '&amp;',
      '<' => '&lt;',
      '>' => '&gt;',
      '"' => '&quot;',
    }

    def output_dynamic_text(string)
      if string.respond_to? :rcdata
        output_text(string.rcdata.gsub(/[<>]/) { ChRef[$&] })
      else
        output_text(string.to_s.gsub(/[&<>]/) { ChRef[$&] })
      end
    end

    def output_dynamic_attvalue(string)
      if string.respond_to? :rcdata
        output_text(string.rcdata.gsub(/[<>"]/) { ChRef[$&] })
      else
        output_text(string.to_s.gsub(/[&<>"]/) { ChRef[$&] })
      end
    end

    # :startdoc:

    def finish
      if @ic.respond_to? :finish
        external_str = @ic.finish
      else
        external_str = @ic.close
      end
      @buf << external_str
      @subcharset_ic.reject! {|subcharset, ic|
        if ic.respond_to? :finish
          begin
            ic.finish != external_str
          rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
            true
          end
        else
          begin
            ic.close != external_str
          rescue Iconv::Failure
            true
          end
        end
      }
      @buf
    end

    def finish_with_xmldecl
      content = finish
      str = "<?xml version=\"1.0\" encoding=\"#{minimal_charset}\"?>"
      if str.respond_to? :encode
        xmldecl = str.encode(@output_encoding, 'US-ASCII')
      else
        xmldecl = Iconv.conv(@output_encoding, 'US-ASCII', str)
      end
      xmldecl + content
    end

    def minimal_charset
      @subcharset_list.each {|subcharset|
        if @subcharset_ic.include? subcharset
          return subcharset
        end
      }
      @output_encoding
    end

    # :stopdoc:

    KcodeCharset = {
      'EUC' => 'EUC-JP',
      'SJIS' => 'Shift_JIS',
      'UTF8' => 'UTF-8',
      'NONE' => 'ISO-8859-1',
    }

    SingleCharPattern = {
      'EUC-JP' => /(?:
         [\x00-\x7f]
        |[\xa1-\xfe][\xa1-\xfe]
        |\x8e[\xa1-\xfe]
        |\x8f[\xa1-\xfe][\xa1-\xfe])/nx,
      'Shift_JIS' => /(?:
         [\x00-\x7f]
        |[\x81-\x9f][\x40-\x7e\x80-\xfc]
        |[\xa1-\xdf]
        |[\xe0-\xfc][\x40-\x7e\x80-\xfc])/nx,
      'UTF-8' => /(?:
         [\x00-\x7f]
        |[\xc0-\xdf][\x80-\xbf]
        |[\xe0-\xef][\x80-\xbf][\x80-\xbf]
        |[\xf0-\xf7][\x80-\xbf][\x80-\xbf][\x80-\xbf]
        |[\xf8-\xfb][\x80-\xbf][\x80-\xbf][\x80-\xbf][\x80-\xbf]
        |[\xfc-\xfd][\x80-\xbf][\x80-\xbf][\x80-\xbf][\x80-\xbf][\x80-\xbf])/nx,
      'ISO-8859-1' => /[\x00-\xff]/n
    }

    FirstCharPattern = {}
    SingleCharPattern.each {|charset, pat|
      FirstCharPattern[charset] = /\A#{pat}/
    }

    SubCharset = {
      'ISO-2022-JP-2' => ['US-ASCII', 'ISO-2022-JP'],
      'ISO-2022-JP-3' => ['US-ASCII', 'ISO-2022-JP'],
      'UTF-16BE' => [],
      'UTF-16LE' => [],
      'UTF-16' => [],
    }
    SubCharset.default = ['US-ASCII']

    # :startdoc:
  end
end
