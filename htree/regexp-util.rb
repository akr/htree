class Regexp
  def disable_capture
    re = ''
    charclass_p = false
    self.source.scan(/\\.|[^\\\(\[\]]+|\(\?|\(|\[|\]/m) {|s|
      case s
      when '('
        if charclass_p
          re << '('
        else
          re << '(?:'
        end
      when '['
        charclass_p = true
        re << s
      when ']'
        charclass_p = false
        re << s
      else
        re << s
      end
    }
    if re.respond_to? :force_encoding
      re.force_encoding(self.encoding)
      Regexp.new(re, self.options)
    else
      Regexp.new(re, self.options, self.kcode)
    end
  end
end

