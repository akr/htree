require 'htree/text'
require 'htree/container'

module HTree
  class Container
    def extract_text
      if @children
        Text.concat(*@children.map {|n| n.extract_text })
      else
        Text.new('')
      end
    end
  end

  class Text
    def extract_text
      self
    end
  end
  
  class Markup
    def extract_text
      Text.new('')
    end
  end
end
