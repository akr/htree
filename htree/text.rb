require 'htree/nodehier'
require 'htree/htmlinfo'

class HTree
  class Text < Leaf
    class << self
      alias new! new
    end

    def Text.new(str)
      new! str.gsub(/&/, '&amp;')
    end

    def initialize(rcdata)
      @rcdata = rcdata
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

    def to_xml
      @rcdata.gsub(/[<>]/) {|s| ChRef[s] }
    end

    def to_xml_attvalue
      "\"#{@rcdata.gsub(/[<>"]/) {|s| ChRef[s] }}\""
    end
  end
end
