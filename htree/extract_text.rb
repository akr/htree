require 'htree/text'
require 'htree/container'

module HTree
  module Container
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
  
  module Markup
    def extract_text
      Text.new('')
    end
  end
end
