require 'htree/text'
require 'htree/doc'
require 'htree/elem'

module HTree
  # :stopdoc:
  module Container
    def extract_text
      Text.concat(*@children.map {|n| n.extract_text })
    end
  end
  # :startdoc:

  class Text
    def extract_text
      self
    end
  end
  
  # :stopdoc:
  module Markup
    def extract_text
      Text.new('')
    end
  end
  # :startdoc:
end
