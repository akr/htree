require 'htree/modules'
require 'htree/raw_string'
require 'htree/htmlinfo'

module HTree
  class Text
    class << self
      alias new! new
    end

    def Text.new(arg)
      if Text === arg
        new! arg.rcdata
      elsif String === arg
        new! arg.gsub(/&/, '&amp;')
      else
        raise TypeError, "cannot initialize Text with #{arg.inspect}"
      end
    end

    def initialize(rcdata)
      init_raw_string
      @rcdata = rcdata && rcdata.dup
    end
    attr_reader :rcdata

    def to_s
      @rcdata.gsub(/&(?:#([0-9]+)|#x([0-9a-fA-F]+)|([A-Za-z][A-Za-z0-9]*));/o) {|s|
        u = nil
        if $1
          u = $1.to_i
        elsif $2
          u = $2.hex
        elsif $3
          u = NamedCharacters[$3]
        end
        if !u || u < 0 || 0x7fffffff < u
          '?'
        elsif u <= 0x7f
          [u].pack("C")
        else
          [u].pack("U").decode_charset('UTF-8')
        end
      }
    end

    ChRef = {
      '>' => '&gt;',
      '<' => '&lt;',
      '"' => '&quot;',
    }

    def generate_xml(out='')
      out << @rcdata.gsub(/[<>]/) {|s| ChRef[s] }
      out
    end

    def generate_xml_attvalue(out='')
      out << "\"#{@rcdata.gsub(/[<>"]/) {|s| ChRef[s] }}\""
      out
    end

    def Text.concat(*args)
      rcdata = ''
      args.each {|arg|
        if Text === arg
          rcdata << arg.rcdata
        else
          rcdata << arg.gsub(/&/, '&amp;')
        end
      }
      new! rcdata
    end
  end
end
