#
# = htree.rb
#
# HTML document tree
#
# Author:: Tanaka Akira <akr@m17n.org>
#
# HTree provides following methods.
#
# - HTree.parse(input) -> HTree::Doc
# - HTree.parse_xml(input) -> HTree::Doc
#

require 'htree/parse'
require 'htree/extract_text'
require 'htree/equality'
require 'htree/inspect'
require 'htree/to_xml'
require 'htree/traverse'
require 'htree/template'
