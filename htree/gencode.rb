require 'htree/encoder'
require 'htree/output'

module HTree
  module Node
    def generate_xml_output_code
      namespaces = HTree::Context::DefaultNamespaces.dup
      namespaces.default = nil
      context = Context.new(namespaces)
      gen = HTree::GenCode.new
      output(gen, context)
      gen.finish
    end
  end

  class GenCode
    def initialize(internal_encoding=Encoder.internal_charset)
      @state = :none
      @buffer = ''
      @internal_encoding = internal_encoding
      @code = <<"End"
lambda {|*args|
user_object = args[0] || nil
output_encoding = args[1] || HTree::Encoder.internal_charset
top_context = args[2] || HTree::DefaultContext
out = HTree::Encoder.new(output_encoding, #{@internal_encoding.dump})
End
    end

    def output_string(str)
      if @state != :string
        flush_buffer
        @state = :string
      end
      @buffer << str
    end

    def output_text(str)
      if @state != :text
        flush_buffer
        @state = :text
      end
      @buffer << str
    end

    def output_xmlns(namespaces)
      unless namespaces.empty?
        flush_buffer
        namespaces.each {|k, v|
          if k
            decl = " xmlns:#{k}=#{v.dump}"
            @code << "out.output_string #{decl.dump} if top_context.namespace_uri(#{k.dump}) != #{v.dump}\n"
          else
            decl = " xmlns=#{v.dump}"
            @code << "out.output_string #{decl.dump} if top_context.namespace_uri(nil) != #{v.dump}\n"
          end
        }
      end
    end

    def flush_buffer
      case @state
      when :string
        @code << "out.output_string #{@buffer.dump}\n"
        @buffer = ''
      when :text
        @code << "out.output_text #{@buffer.dump}\n"
        @buffer = ''
      end
    end

    def finish
      flush_buffer
      @code << "out.finish\n"
      @code << "}\n"
      @code
    end
  end
end
