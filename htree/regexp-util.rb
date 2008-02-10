class Regexp
  def disable_capture
    re = ''
    self.source.scan(/\\.|[^\\\(]+|\(\?|\(/m) {|s|
      if s == '('
        re << '(?:'
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

