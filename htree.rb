# htree.rb - HTML/XML tree library
#
# Copyright (C) 2003,2004 Tanaka Akira  <akr@fsij.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.
#
# = htree.rb
#
# HTML/XML document tree
#
# Author:: Tanaka Akira <akr@fsij.org>
#
# == Features
#
# - Permissive unified HTML/XML parser
# - byte-to-byte round-tripping unparser
# - XML namespace support
# - Dedicated class for escaped string.  This ease sanitization.
# - XHTML/XML generator
# - template engine: link:files/htree/template_rb.html
# - recursive template expansion
# - REXML tree generator: link:files/htree/rexml_rb.html
#
# == Example
#
# The following one-liner prints parsed tree object.
#
#   % ruby -rhtree -e 'pp HTree(ARGF)' html-file
#
# The following two-line script convert HTML to XHTML.
#
#   require 'htree'
#   HTree(STDIN).display_xml
#
# The conversion method to REXML is provided as to_rexml.
#
#     HTree(...).to_rexml
#
# == Module/Class Hierarchy
#
# * HTree
#   * HTree::Name
#   * HTree::Context
#   * HTree::Location
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
# - Generation Methods
#   - HTree::Node#display_xml -> STDOUT
#   - HTree::Node#display_xml(<i>out</i>) -> <i>out</i>
#   - HTree::Node#display_xml(<i>out</i>, <i>encoding</i>) -> <i>out</i>
#   - HTree::Text#to_s -> String
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
#   - HTree::Elem::Location#attributes -> Hash[HTree::Name -> HTree::Location]
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
