require 'htree/tag'
require 'htree/container'
require 'htree/context'
require 'htree/output'

module HTree
  module Node
    # to_xml encodes the node in XML.
    #
    # The optional argument, <i>encoding</i>,
    # specifies output MIME charset (character encoding).
    # If it is not specified, Encoder.internal_charset is used.
    def to_xml(encoding=Encoder.internal_charset)
      encoder = HTree::Encoder.new(encoding)
      self.output(encoder, HTree::DefaultContext)
      encoder.finish
    end
  end
end
