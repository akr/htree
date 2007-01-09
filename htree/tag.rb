# htree/tag.rb - htree tag class.
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

require 'htree/raw_string'
require 'htree/text'
require 'htree/scan' # for Pat::Name and Pat::Nmtoken
require 'htree/context'
require 'htree/name'
require 'htree/fstr'

module HTree
  # :stopdoc:

  class STag
    def initialize(name, attributes=[], inherited_context=DefaultContext)
      init_raw_string
      # normalize xml declaration name and attribute value.
      attributes = attributes.map {|aname, val|
        if !(Name === aname) && /\A(?:#{Pat::Name}?\{.*\})?#{Pat::Nmtoken}\z/o !~ aname
          raise HTree::Error, "invalid attribute name: #{aname.inspect}"
        end
        if !(Name === aname) && /\Axmlns(?:\z|:)/ =~ aname
          aname = Name.parse_attribute_name(aname, nil)
        end
        val = val.to_node if HTree::Location === val
        val = Text.new(val) unless Text === val
        [aname, val]
      }

      @inherited_context = inherited_context
      @xmlns_decls = {}

      # validate namespace consistency of given Name objects.
      if Name === name
        @xmlns_decls[name.namespace_prefix] = name.namespace_uri
      end
      attributes.each {|aname, text|
        next unless Name === aname
        next if aname.xmlns?
        if aname.namespace_prefix && aname.namespace_uri
          if @xmlns_decls.include? aname.namespace_prefix
            if @xmlns_decls[aname.namespace_prefix] != aname.namespace_uri
              raise ArgumentError, "inconsistent namespace use: #{aname.namespace_prefix} is used as #{@xmlns_decls[aname.namespace_prefix]} and #{aname.namespace_uri}"
            end
          else
            @xmlns_decls[aname.namespace_prefix] = aname.namespace_uri
          end
        end
      }

      attributes.each {|aname, text|
        next unless Name === aname
        next unless aname.xmlns?
        next if @xmlns_decls.include? aname.local_name
        if aname.local_name
          @xmlns_decls[aname.local_name] = text.to_s
        else
          uri = text.to_s
          @xmlns_decls[nil] = uri
        end
      }

      @context = make_context(@inherited_context)

      if Name === name
        @name = name
      else
        @name = Name.parse_element_name(name, @context)
      end

      @attributes = attributes.map {|aname, text|
        aname = Name.parse_attribute_name(aname, @context) unless Name === aname
        if !aname.namespace_prefix && !aname.namespace_uri.empty?
          # xxx: should recover error?
          raise HTree::Error, "global attribute without namespace prefix: #{aname.inspect}"
        end
        [aname, text]
      }
      @attributes.freeze
    end
    attr_reader :attributes, :inherited_context, :context

    def element_name
      @name
    end

    def make_context(inherited_context)
      inherited_context.subst_namespaces(@xmlns_decls)
    end

    def each_namespace_attribute
      @xmlns_decls.each {|name, uri|
        yield name, uri
      }
      nil
    end

    def each_attribute
      @attributes.each {|name, text|
        next if name.xmlns?
        yield name, text
      }
      nil
    end
  end

  class ETag
    def initialize(qualified_name)
      init_raw_string
      @qualified_name = HTree.frozen_string(qualified_name)
    end
    attr_reader :qualified_name
  end

  # :startdoc:
end
