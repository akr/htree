#
# = htree.rb
#
# HTML/XML document tree
#
# Author:: Tanaka Akira <akr@m17n.org>
#
# == Examples
#
# === Example 1: dump a document tree
#
#   % ruby -rhtree -e 'pp HTree.parse(ARGF)' html-file
#
# == Method Summary
#
# HTree provides following methods.
#
# - HTree.parse(input) -> HTree::Doc
# - HTree.parse_xml(input) -> HTree::Doc
#
# - HTree::Node#to_xml([encoding]) -> String
#

require 'htree/parse'
require 'htree/extract_text'
require 'htree/equality'
require 'htree/inspect'
require 'htree/to_xml'
require 'htree/traverse'
require 'htree/template'
