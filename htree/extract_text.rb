require 'htree/text'
require 'htree/doc'
require 'htree/elem'

module HTree
  module Node
    def extract_text
      p self
      raise NotImplementedError
    end
  end

  # :stopdoc:
  module Container
    def extract_text
      Text.concat(*@children.map {|n| n.extract_text })
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
  # :startdoc:
end
