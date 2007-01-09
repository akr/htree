# htree/inspect.rb - htree inspect method
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

require 'pp'
require 'htree/doc'
require 'htree/elem'
require 'htree/leaf'
require 'htree/tag'
require 'htree/output'
require 'htree/raw_string'

module HTree
  # :stopdoc:
  class Doc
    def pretty_print(q)
      q.object_group(self) { @children.each {|elt| q.breakable; q.pp elt } }
    end
    alias inspect pretty_print_inspect
  end

  class Elem
    def pretty_print(q)
      if @empty
        q.group(1, '{emptyelem', '}') {
          q.breakable; q.pp @stag
        }
      else
        q.group(1, "{elem", "}") {
          q.breakable; q.pp @stag
          @children.each {|elt| q.breakable; q.pp elt }
          if @etag
            q.breakable; q.pp @etag
          end
        }
      end
    end
    alias inspect pretty_print_inspect
  end

  module Leaf
    def pretty_print(q)
      q.group(1, '{', '}') {
        q.text self.class.name.sub(/.*::/,'').downcase
        if rs = @raw_string
          rs.scan(/[^\r\n]*(?:\r\n?|\n|[^\r\n]\z)/) {|line|
            q.breakable
            q.pp line
          }
        elsif self.respond_to? :display_xml
          q.breakable
          q.text self.display_xml('')
        end
      }
    end
    alias inspect pretty_print_inspect
  end

  class Name
    def inspect
      if xmlns?
        @local_name ? "xmlns:#{@local_name}" : "xmlns"
      elsif !@namespace_uri || @namespace_uri.empty?
        @local_name
      elsif @namespace_prefix
        "#{@namespace_prefix}{#{@namespace_uri}}#{@local_name}"
      elsif @namespace_prefix == false
        "-{#{@namespace_uri}}#{@local_name}"
      else
        "{#{@namespace_uri}}#{@local_name}"
      end
    end
  end

  class STag
    def pretty_print(q)
      q.group(1, '<', '>') {
        q.text @name.inspect

        @attributes.each {|n, t|
          q.breakable
          q.text "#{n.inspect}=\"#{t.to_attvalue_content}\""
        }
      }
    end
    alias inspect pretty_print_inspect
  end

  class ETag
    def pretty_print(q)
      q.group(1, '</', '>') {
        q.text @qualified_name
      }
    end
    alias inspect pretty_print_inspect
  end

  class BogusETag
    def pretty_print(q)
      q.group(1, '{', '}') {
        q.text self.class.name.sub(/.*::/,'').downcase
        if rs = @raw_string
          q.breakable
          q.text rs
        else
          q.text "</#{@qualified_name}>"
        end
      }
    end
  end
  # :startdoc:
end
