require 'htree/output'

module HTree
  module Node
    # HTree::Node#display_xml prints the node as XML.
    #
    # The first optional argument, <i>out</i>,
    # specifies output target.
    # It should respond to <tt><<</tt>.
    # If it is not specifies, $stdout is used.
    #
    # The second optional argument, <i>encoding</i>,
    # specifies output MIME charset (character encoding).
    # If it is not specified, HTree::Encoder.internal_charset is used.
    #
    # HTree::Node#display_xml returns <i>out</i>.
    def display_xml(out=$stdout, encoding=HTree::Encoder.internal_charset)
      encoder = HTree::Encoder.new(encoding)
      self.output(encoder, HTree::DefaultContext)
      out << encoder.finish
      out
    end
  end
end