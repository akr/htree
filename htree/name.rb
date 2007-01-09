# htree/name.rb - htree name class.
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

require 'htree/scan' # for Pat::Nmtoken
require 'htree/context'

module HTree
  # Name represents a element name and attribute name.
  # It consists of a namespace prefix, a namespace URI and a local name.
  class Name
=begin
element name                    prefix  uri     localname
{u}n, n with xmlns=u            nil     'u'     'n'
p{u}n, p:n with xmlns:p=u       'p'     'u'     'n'
n with xmlns=''                 nil     ''      'n'

attribute name
xmlns=                          'xmlns' nil     nil
xmlns:n=                        'xmlns' nil     'n'
p{u}n=, p:n= with xmlns:p=u     'p'     'u'     'n'
n=                              nil     ''      'n'
=end
    def Name.parse_element_name(name, context)
      if /\{(.*)\}/ =~ name
        # "{u}n" means "use default namespace",
        # "p{u}n" means "use the specified prefix p"
        $` == '' ? Name.new(nil, $1, $') : Name.new($`, $1, $')
      elsif /:/ =~ name && !context.namespace_uri($`).empty?
        Name.new($`, context.namespace_uri($`), $')
      elsif !context.namespace_uri(nil).empty?
        Name.new(nil, context.namespace_uri(nil), name)
      else
        Name.new(nil, '', name)
      end
    end

    def Name.parse_attribute_name(name, context)
      if name == 'xmlns'
        Name.new('xmlns', nil, nil)
      elsif /\Axmlns:/ =~ name
        Name.new('xmlns', nil, $')
      elsif /\{(.*)\}/ =~ name
        case $`
        when ''; Name.new(nil, $1, $')
        else Name.new($`, $1, $')
        end
      elsif /:/ =~ name && !context.namespace_uri($`).empty?
        Name.new($`, context.namespace_uri($`), $')
      else
        Name.new(nil, '', name)
      end
    end

    NameCache = {}
    def Name.new(namespace_prefix, namespace_uri, local_name)
      key = [namespace_prefix, namespace_uri, local_name, self]
      NameCache.fetch(key) {
        0.upto(2) {|i| key[i] = key[i].dup.freeze if key[i] }
        NameCache[key] = super(key[0], key[1], key[2])
      }
    end

    def initialize(namespace_prefix, namespace_uri, local_name)
      @namespace_prefix = namespace_prefix
      @namespace_uri = namespace_uri
      @local_name = local_name
      if @namespace_prefix && /\A#{Pat::Nmtoken}\z/o !~ @namespace_prefix
        raise HTree::Error, "invalid namespace prefix: #{@namespace_prefix.inspect}"
      end
      if @local_name && /\A#{Pat::Nmtoken}\z/o !~ @local_name
        raise HTree::Error, "invalid local name: #{@local_name.inspect}"
      end
      if @namespace_prefix == 'xmlns'
        unless @namespace_uri == nil
          raise HTree::Error, "Name object for xmlns:* must not have namespace URI: #{@namespace_uri.inspect}"
        end
      else
        unless String === @namespace_uri 
          raise HTree::Error, "invalid namespace URI: #{@namespace_uri.inspect}"
        end
      end
    end
    attr_reader :namespace_prefix, :namespace_uri, :local_name

    def xmlns?
      @namespace_prefix == 'xmlns' && @namespace_uri == nil
    end

    def universal_name
      if @namespace_uri && !@namespace_uri.empty?
        "{#{@namespace_uri}}#{@local_name}"
      else
        @local_name.dup
      end
    end

    def qualified_name
      if @namespace_uri && !@namespace_uri.empty?
        if @namespace_prefix
          "#{@namespace_prefix}:#{@local_name}"
        else
          @local_name.dup
        end
      elsif @local_name
        @local_name.dup
      else
        "xmlns"
      end
    end

    def to_s
      if @namespace_uri && !@namespace_uri.empty?
        if @namespace_prefix
          "#{@namespace_prefix}{#{@namespace_uri}}#{@local_name}"
        else
          "{#{@namespace_uri}}#{@local_name}"
        end
      elsif @local_name
        @local_name.dup
      else
        "xmlns"
      end
    end
  end
end
