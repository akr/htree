#
# = htree.rb
#
# HTML/XML document tree
#
# Author:: Tanaka Akira <akr@m17n.org>
#
# == Features
#
# - Template Engine: link:files/htree/template_rb.html
#
# == Examples
#
# === Example 1: dump a document tree
#
#   % ruby -rhtree -e 'pp HTree.parse(ARGF)' html-file
#
# == Module/Class Hierarchy
#
# * HTree
#   * HTree::Name
#   * HTree::Context
#   * HTree::Loc
#   * HTree::Node
#     * HTree::Doc
#     * HTree::Elem
#     * HTree::Text
#     * HTree::XMLDecl
#     * HTree::DocType
#     * HTree::ProcIns
#     * HTree::Comment
#     * HTree::BogusETag
# * HTree::Error
#
# == Method Summary
#
# HTree provides following methods.
#
# - HTree(<i>html_string</i>) -> HTree::Doc
# - HTree.parse(input) -> HTree::Doc
# - HTree.parse_xml(input) -> HTree::Doc
#
# - HTree::Node#to_xml([encoding]) -> String
#
# - HTree.expand_template{<i>template_string</i>}
# - HTree.expand_template(<i>encoding</i>){<i>template_string</i>}
# - HTree.expand_template(<i>encoding</i>, <i>out</i>){<i>template_string</i>} -> <i>out</i>
# - HTree.compile_template(<i>template_string</i>) -> Module
# - HTree{<i>template_string</i>} -> HTree::Doc
#

require 'htree/parse'
require 'htree/extract_text'
require 'htree/equality'
require 'htree/inspect'
require 'htree/to_xml'
require 'htree/traverse'
require 'htree/template'
