require 'htree/tag'
require 'htree/container'
require 'htree/context'
require 'htree/output'

module HTree
  module Node
    def to_xml
      # xxx: take charset as optional argument.
      encoder = HTree::Encoder.new(Encoder.internal_charset)
      self.output(encoder, HTree::DefaultContext)
      encoder.finish
    end
  end
end
