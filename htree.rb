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
# - REXML Tree Generator: link:files/htree/rexml_rb.html
#
# == Example
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
#
# - Genrating Methods
#   - HTree::Node#display_xml -> STDOUT
#   - HTree::Node#display_xml(<i>out</i>) -> <i>out</i>
#   - HTree::Node#display_xml(<i>out</i>, <i>encoding</i>) -> <i>out</i>
#
# - Template Methods
#   - HTree.expand_template{<i>template_string</i>} -> STDOUT
#   - HTree.expand_template(<i>out</i>){<i>template_string</i>} -> <i>out</i>
#   - HTree.expand_template(<i>out</i>, <i>encoding</i>){<i>template_string</i>} -> <i>out</i>
#   - HTree.compile_template(<i>template_string</i>) -> Module
#   - HTree{<i>template_string</i>} -> HTree::Doc
#
# - Traverse Methods
#   - HTree::Elem#attributes -> Hash[HTree::Name -> HTree::Text]
#   - HTree::Elem::Loc#attributes -> Hash[HTree::Name -> HTree::Location]
#
# - Predicate Methods
#   - HTree::Traverse#doc? -> true or false
#   - HTree::Traverse#elem? -> true or false
#   - HTree::Traverse#text? -> true or false
#   - HTree::Traverse#xmldecl? -> true or false
#   - HTree::Traverse#doctype? -> true or false
#   - HTree::Traverse#procins? -> true or false
#   - HTree::Traverse#comment? -> true or false
#   - HTree::Traverse#bogusetag? -> true or false
#
# - REXML Tree Generator
#   - HTree::Node#to_rexml -> REXML::Child

require 'htree/parse'
require 'htree/extract_text'
require 'htree/equality'
require 'htree/inspect'
require 'htree/display'
require 'htree/loc'
require 'htree/traverse'
require 'htree/template'
require 'htree/rexml'
