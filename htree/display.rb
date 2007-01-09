# htree/display.rb - htree display methods.
#
# Copyright (C) 2004,2005 Tanaka Akira  <akr@fsij.org>
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

require 'htree/output'

module HTree
  module Node
    # HTree::Node#display_xml prints the node as XML.
    #
    # The first optional argument, <i>out</i>,
    # specifies output target.
    # It should respond to <tt><<</tt>.
    # If it is not specified, $stdout is used.
    #
    # The second optional argument, <i>encoding</i>,
    # specifies output MIME charset (character encoding).
    # If it is not specified, HTree::Encoder.internal_charset is used.
    #
    # HTree::Node#display_xml returns <i>out</i>.
    def display_xml(out=$stdout, encoding=HTree::Encoder.internal_charset)
      encoder = HTree::Encoder.new(encoding)
      self.output(encoder, HTree::DefaultContext)
      # don't call finish_with_xmldecl because self already has a xml decl.
      out << encoder.finish
      out
    end

    # HTree::Node#display_html prints the node as HTML.
    #
    # The first optional argument, <i>out</i>,
    # specifies output target.
    # It should respond to <tt><<</tt>.
    # If it is not specified, $stdout is used.
    #
    # The second optional argument, <i>encoding</i>,
    # specifies output MIME charset (character encoding).
    # If it is not specified, HTree::Encoder.internal_charset is used.
    #
    # HTree::Node#display_html returns <i>out</i>.
    def display_html(out=$stdout, encoding=HTree::Encoder.internal_charset)
      encoder = HTree::Encoder.new(encoding)
      encoder.html_output = true
      self.output(encoder, HTree::HTMLContext)
      out << encoder.finish
      out
    end

  end
end
