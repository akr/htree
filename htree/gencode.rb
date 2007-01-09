# htree/gencode.rb - htree code generator.
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

require 'htree/encoder'
require 'htree/output'

# :stopdoc:

module HTree
  module Node
    def generate_xml_output_code(outvar='out', contextvar='top_context')
      namespaces = HTree::Context::DefaultNamespaces.dup
      namespaces.default = nil
      context = Context.new(namespaces)
      gen = HTree::GenCode.new(outvar, contextvar)
      output(gen, context)
      gen.finish
    end
  end

  class GenCode
    def initialize(outvar, contextvar, internal_encoding=Encoder.internal_charset)
      @outvar = outvar
      @contextvar = contextvar
      @state = :none
      @buffer = ''
      @internal_encoding = internal_encoding
      @code = ''
      @html_output = nil
    end
    attr_reader :outvar, :contextvar

    def html_output?
      @html_output
    end

    def html_output=(flag)
      @html_output = flag
    end

    class CDATABuffer
      def initialize
        @buf = ''
      end

      def html_output?
        true
      end

      def not_valid_for_html_cdata(*args)
        raise ArgumentError, "CDATA content only accept texts."
      end
      alias output_slash_if_xml not_valid_for_html_cdata
      alias output_cdata_content not_valid_for_html_cdata
      alias output_dynamic_attvalue not_valid_for_html_cdata

      def output_string(string)
        @buf << string
      end

      def output_text(string)
        @buf << string
      end

      ChRef = {
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;',
        '"' => '&quot;',
      }

      def output_dynamic_text(string)
        if string.respond_to? :rcdata
          @buf << string.rcdata.gsub(/[<>]/) { ChRef[$&] }
        else
          @buf << string.to_s.gsub(/[&<>]/) { ChRef[$&] }
        end
      end

      def result
        if %r{[<>]} =~ @buf
          raise ArgumentError, "cdata contains non-text : #{@buf.inspect}"
        end
        str = HTree::Text.parse_pcdata(@buf).to_s
        if %r{</} =~ str
          raise ArgumentError, "cdata contains '</' : #{str.inspect}"
        end
        str
      end
    end

    def output_cdata_content(content, context)
      tmp_outvar = @outvar + '_tmp'
      output_logic_line "#{@outvar} = #{@outvar}.output_cdata_content_do(#{@outvar},"
      output_logic_line "lambda { #{@outvar} = HTree::GenCode::CDATABuffer.new },"
      output_logic_line "lambda {"
      content.each {|n| n.output(self, context) }
      output_logic_line "},"
      output_logic_line "lambda {|#{tmp_outvar}| #{tmp_outvar}.output_string(#{@outvar}.result) })"
    end

    def output_slash_if_xml
      output_logic_line "#{@outvar}.output_slash_if_xml"
    end

    def output_dynamic_text(expr)
      flush_buffer
      @code << "#{@outvar}.output_dynamic_text((#{expr}))\n"
    end

    def output_dynamic_tree(expr, context_expr)
      flush_buffer
      @code << "(#{expr}).output(#{@outvar}, #{context_expr})\n"
    end

    def output_dynamic_attvalue(expr)
      flush_buffer
      @code << "#{@outvar}.output_dynamic_attvalue((#{expr}))\n"
    end

    def output_logic_line(line)
      flush_buffer
      @code << line << "\n"
    end
                       
    def output_string(str)
      return if str.empty?
      if @state != :string
        flush_buffer
        @state = :string
      end
      @buffer << str
    end

    def output_text(str)
      return if str.empty?
      if /\A[\s\x21-\x7e]+\z/ =~ str && @state == :string
        # Assumption: external charset can represent white spaces and
        # ASCII printable.
        output_string(str)
        return 
      end
      if @state != :text
        flush_buffer
        @state = :text
      end
      @buffer << str
    end

    ChRef = {
      '&' => '&amp;',
      '>' => '&gt;',
      '<' => '&lt;',
      '"' => '&quot;',
    }
    def output_xmlns(namespaces)
      unless namespaces.empty?
        flush_buffer
        namespaces.each {|k, v|
          if k
            ks = k.dump
            aname = "xmlns:#{k}"
          else
            ks = "nil"
            aname = "xmlns"
          end
          @code << "if #{@contextvar}.namespace_uri(#{ks}) != #{v.dump}\n"
          output_string " #{aname}=\""
          output_text v.gsub(/[&<>"]/) {|s| ChRef[s] }
          output_string '"'
          flush_buffer
          @code << "end\n"
        }
      end
    end

    def flush_buffer
      return if @buffer.empty?
      case @state
      when :string
        @code << "#{@outvar}.output_string #{@buffer.dump}\n"
        @buffer = ''
      when :text
        @code << "#{@outvar}.output_text #{@buffer.dump}\n"
        @buffer = ''
      end
    end

    def finish
      flush_buffer
      @code
    end
  end
end

# :startdoc:
