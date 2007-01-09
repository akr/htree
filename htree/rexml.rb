# htree/rexml.rb - rexml tree generator.
#
# Copyright (C) 2004 Tanaka Akira  <akr@fsij.org>
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
# = REXML Tree Generator
#
# HTree::Node#to_rexml is used for converting HTree to REXML.
#
# == Method Summary
#
# - HTree::Node#to_rexml -> REXML::Child
#
# == Example
#
#   HTree.parse(...).to_rexml #=> REXML::Document
#
# == Comparison between HTree and REXML.
#
# - HTree parser is permissive HTML/XML parser.
#   REXML parser is strict XML parser.
#   HTree is recommended if you need to parse realworld HTML.
#   REXML is recommended if you need strict error checking.
# - HTree object is immutable.
#   REXML object is mutable.
#   REXML should be used if you need modification.
#
require 'htree/modules'
require 'htree/output' # HTree::DocType#generate_content

module HTree
  module Node
    # convert to REXML tree.
    def to_rexml
      require 'rexml/document'
      to_rexml_internal(nil, DefaultContext)
    end
  end

  # :stopdoc:

  class Doc
    def to_rexml_internal(parent, context)
      raise ArgumentError, "parent must be nil" if parent != nil
      result = REXML::Document.new
      self.children.each {|c|
        c.to_rexml_internal(result, context)
      }
      result
    end
  end

  class Elem
    def to_rexml_internal(parent, context)
      ename = self.element_name
      ns_decl = {}
      if context.namespace_uri(ename.namespace_prefix) != ename.namespace_uri
        ns_decl[ename.namespace_prefix] = ename.namespace_uri
      end

      if ename.namespace_prefix
        result = REXML::Element.new("#{ename.namespace_prefix}:#{ename.local_name}", parent)
      else
        result = REXML::Element.new(ename.local_name, parent)
      end

      self.each_attribute {|aname, atext|
        if aname.namespace_prefix
          if context.namespace_uri(aname.namespace_prefix) != aname.namespace_uri
            ns_decl[aname.namespace_prefix] = aname.namespace_uri
          end
          result.add_attribute("#{aname.namespace_prefix}:#{aname.local_name}", atext.to_s)
        else
          result.add_attribute(aname.local_name, atext.to_s)
        end
      }

      ns_decl.each {|k, v|
        if k
          result.add_namespace(k, v)
        else
          result.add_namespace(v)
        end
      }
      context = context.subst_namespaces(ns_decl)

      self.children.each {|c|
        c.to_rexml_internal(result, context)
      }
      result
    end
  end

  class Text
    def to_rexml_internal(parent, context)
      rcdata = self.rcdata.gsub(/[<>]/) { Encoder::ChRef[$&] }
      REXML::Text.new(rcdata, true, parent, true)
    end
  end

  class XMLDecl
    def to_rexml_internal(parent, context)
      r = REXML::XMLDecl.new(self.version, self.encoding, self.standalone)
      parent << r if parent
      r
    end
  end

  class DocType
    def to_rexml_internal(parent, context)
      REXML::DocType.new([self.root_element_name, self.generate_content], parent)
    end
  end

  class ProcIns
    def to_rexml_internal(parent, context)
      r = REXML::Instruction.new(self.target, self.content)
      parent << r if parent
      r
    end
  end

  class Comment
    def to_rexml_internal(parent, context)
      REXML::Comment.new(self.content, parent)
    end
  end

  class BogusETag
    def to_rexml_internal(parent, context)
      nil
    end
  end

  # :startdoc:
end
