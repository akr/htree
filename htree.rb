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
# - Parsing Methods
#   - HTree(<i>html_string</i>) -> HTree::Doc
#   - HTree.parse(<i>input</i>) -> HTree::Doc
#   - HTree.parse_xml(<i>input</i>) -> HTree::Doc
#
# - Genrating Methods
#   - HTree::Node#display_xml -> STDOUT
#   - HTree::Node#display_xml(<i>encoding</i>) -> STDOUT
#   - HTree::Node#display_xml(<i>encoding</i>, <i>out</i>) -> <i>out</i>
#
# - Template Methods
#   - HTree.expand_template{<i>template_string</i>} -> STDOUT
#   - HTree.expand_template(<i>encoding</i>){<i>template_string</i>} -> STDOUT
#   - HTree.expand_template(<i>encoding</i>, <i>out</i>){<i>template_string</i>} -> <i>out</i>
#   - HTree.compile_template(<i>template_string</i>) -> Module
#   - HTree{<i>template_string</i>} -> HTree::Doc
#

require 'htree/parse'
require 'htree/extract_text'
require 'htree/equality'
require 'htree/inspect'
require 'htree/display'
require 'htree/traverse'
require 'htree/template'
