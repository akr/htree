require 'iconv'

module HTree
  class Encoder
    def Encoder.internal_charset
      KcodeCharset[$KCODE]
    end

    def initialize(output_encoding, internal_encoding=Encoder.internal_charset)
      @buf = ''
      @internal_encoding = internal_encoding
      @output_encoding = output_encoding
      @ic = Iconv.new(output_encoding, @internal_encoding)
      @charpat = FirstCharPattern[internal_encoding]

      @subcharset_list = SubCharset[output_encoding] || []
      @subcharset_ic = {}
      @subcharset_list.each {|subcharset|
        @subcharset_ic[subcharset] = Iconv.new(subcharset, @internal_encoding)
      }
    end

    def output_string(internal_str, external_str=@ic.iconv(internal_str))
      @buf << external_str
      @subcharset_ic.reject! {|subcharset, ic|
        begin
          ic.iconv(internal_str) != external_str
        rescue Iconv::Failure
          true
        end
      }
      nil
    end

    def output_text(string)
      begin
        output_string string, @ic.iconv(string)
      rescue Iconv::IllegalSequence, Iconv::InvalidCharacter => e
        output_string string[0, string.length - e.failed.length], e.success
        unless @charpat =~ e.failed
          raise ArgumentError, "cannot extract first character"
        end
        char = $&
        rest = $'
        ucode = Iconv.conv("UTF-8", @internal_encoding, char).unpack("U")[0]
        output_string "&##{ucode};"
        string = rest
        retry
      end
    end

    def finish
      external_str = @ic.close
      @buf << external_str
      @subcharset_ic.reject! {|subcharset, ic|
        begin
          ic.close != external_str
        rescue Iconv::Failure
          true
        end
      }
      @buf
    end

    def minimal_charset
      @subcharset_list.each {|subcharset|
        if @subcharset_ic.include? subcharset
          return subcharset
        end
      }
      @output_encoding
    end

    KcodeCharset = {
      'EUC' => 'EUC-JP',
      'SJIS' => 'Shift_JIS',
      'UTF8' => 'UTF-8',
      'NONE' => 'ISO-8859-1',
    }

    FirstCharPattern = {
      'EUC-JP' => /\A(?:
         [\x00-\x7f]
        |[\xa1-\xfe][\xa1-\xfe]
        |\x8e[\xa1-\xfe]
        |\x8f[\xa1-\xfe][\xa1-\xfe])/nx,
      'Shift_JIS' => /\A(?:
         [\x00-\x7f]
        |[\x81-\x9f][\x40-\x7e\x80-\xfc]
        |[\xa1-\xdf]
        |[\xe0-\xfc][\x40-\x7e\x80-\xfc])/nx,
      'UTF-8' => /\A(?:
         [\x00-\x7f]
        |[\xc0-\xdf][\x80-\xbf]
        |[\xe0-\xef][\x80-\xbf][\x80-\xbf]
        |[\xf0-\xf7][\x80-\xbf][\x80-\xbf][\x80-\xbf]
        |[\xf8-\xfb][\x80-\xbf][\x80-\xbf][\x80-\xbf][\x80-\xbf]
        |[\xfc-\xfd][\x80-\xbf][\x80-\xbf][\x80-\xbf][\x80-\xbf][\x80-\xbf])/nx,
      'ISO-8859-1' => /\A[\x00-\xff]/n
    }

    SubCharset = {
      'ISO-2022-JP-2' => ['US-ASCII', 'ISO-2022-JP'],
      'ISO-2022-JP-3' => ['US-ASCII', 'ISO-2022-JP'],
      'UTF-16BE' => [],
      'UTF-16LE' => [],
      'UTF-16' => [],
    }
    SubCharset.default = ['US-ASCII']
  end
end