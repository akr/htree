require 'htree/gencode'

def HTree.expand_template(encoding=HTree::Encoder.internal_charset, out=STDOUT, &block)
  template = block.call
  HTree::TemplateCompiler.new.expand_template(template, encoding, out, block)
end

def HTree(arg=nil, &block)
  if block_given?
    template = block.call
    HTree.parse(HTree::TemplateCompiler.new.expand_fragment_template(template, HTree::Encoder.internal_charset, '', block))
  else
    HTree.parse(arg)
  end
end

def HTree.compile_template(template)
  code = HTree::TemplateCompiler.new.compile_template(template)
  eval(code)
end

class HTree::TemplateCompiler
  IGNORABLE_ELEMENTS = {
    'span' => true,
    #'div' => true,
    '{http://www.w3.org/1999/xhtml}span' => true,
    #'{http://www.w3.org/1999/xhtml}div' => true,
  }

  def initialize
    @gensym_id = 0
  end

  def gensym(suffix='')
    @gensym_id += 1
    "g#{@gensym_id}#{suffix}"
  end

  def expand_template(template, encoding, out, binding)
    template = HTree.parse(template)
    outvar = gensym('out')
    contextvar = gensym('top_context')
    code = <<"End"
#{outvar} = HTree::Encoder.new(#{encoding.dump})
#{contextvar} = HTree::DefaultContext
#{compile_template_body(outvar, contextvar, template, false)}\
#{outvar}.finish_with_xmldecl
End
    result = eval(code, binding)
    out << result
    out
  end

  def expand_fragment_template(template, encoding, out, binding)
    template = HTree.parse(template)
    outvar = gensym('out')
    contextvar = gensym('top_context')
    code = <<"End"
#{outvar} = HTree::Encoder.new(#{encoding.dump})
#{contextvar} = HTree::DefaultContext
#{compile_template_body(outvar, contextvar, template, false)}\
#{outvar}.finish
End
    result = eval(code, binding)
    out << result
    out
  end

  def compile_template(src)
    srcdoc = HTree.parse(src)
    templates = []
    body = extract_templates(srcdoc, templates, true)
    methods = []
    templates.each {|name_args, node|
      methods << compile_global_template(name_args, node)
    }
    <<"End"
require 'htree/encoder'
require 'htree/context'
Module.new {
module_function
#{methods.join('').chomp}
}
End
  end

  def template_attribute?(name)
    /\A_/ =~ name.local_name
  end

  def extract_templates(node, templates, is_toplevel)
    case node
    when HTree::Doc
      subst = {}
      node.children.each_with_index {|n, i|
        subst[i] = extract_templates(n, templates, is_toplevel)
      }
      node.subst_subnode(subst)
    when HTree::Elem
      ht_attrs, rest_attrs = node.attributes.partition {|name, text| template_attribute? name }
      ht_attrs = ht_attrs.sort_by {|htname, text| htname.universal_name }
      case ht_attrs.map {|htname, text| htname.universal_name }
      when []
        subst = {}
        node.children.each_with_index {|n, i|
          subst[i] = extract_templates(n, templates, is_toplevel)
        }
        node.subst_subnode(subst)
      when ['_template']
        name_fargs = ht_attrs[0][1].to_s
        templates << [name_fargs, node.subst_subnode('_template' => nil)]
        nil
      else
        if is_toplevel
          raise HTree::Error, "unexpected template attributes in toplevel: #{ht_attrs.inspect}"
        else
          node
        end
      end
    else
      node
    end
  end

  ID_PAT = /[a-z][a-z0-9_]*/
  NAME_FARGS_PAT = /(#{ID_PAT})(?:\(\s*(|#{ID_PAT}\s*(?:,\s*#{ID_PAT}\s*)*)\))?/
  def compile_global_template(name_fargs, node)
    unless /\A#{NAME_FARGS_PAT}\z/o =~ name_fargs
      raise HTree::Error, "invalid template declaration: #{name_fargs}"
    end
    name = $1
    fargs = $2 ? $2.scan(ID_PAT) : []

    outvar = gensym('out')
    contextvar = gensym('top_context')
    args2 = [outvar, contextvar, *fargs]

    <<"End"
def #{name}(#{fargs.join(',')})
HTree.parse(_xml_#{name}(#{fargs.join(',')}))
end
def _xml_#{name}(#{fargs.join(',')})
#{outvar} = HTree::Encoder.new(HTree::Encoder.internal_charset)
#{contextvar} = HTree::DefaultContext
_ht_#{name}(#{args2.join(',')})
#{outvar}.finish
end
def _ht_#{name}(#{args2.join(',')})
#{compile_template_body(outvar, contextvar, node, false)}\
end
End
  end

  def compile_local_template(name_fargs, node, local_templates)
    unless /\A#{NAME_FARGS_PAT}\z/o =~ name_fargs
      raise HTree::Error, "invalid template declaration: #{name_fargs}"
    end
    name = $1
    fargs = $2 ? $2.scan(ID_PAT) : []

    outvar = gensym('out')
    contextvar = gensym('top_context')
    args2 = [outvar, contextvar, *fargs]

    <<"End"
#{name} = lambda {|#{args2.join(',')}|
#{compile_template_body(outvar, contextvar, false, node)}\
}
End
  end

  def compile_template_body(outvar, contextvar, node, is_toplevel, local_templates={})
    code = ''
    subtemplates = []
    body = extract_templates(node, subtemplates, is_toplevel)
    unless subtemplates.empty?
      local_templates = local_templates.dup
      subtemplates.each {|sub_name_args, sub_node|
        sub_name = sub_name_args[ID_PAT]
        local_templates[sub_name] = sub_name
        code << "#{sub_name} = "
      }
      code << "nil\n"
      subtemplates.each {|sub_name_args, sub_node|
        code << compile_local_template(sub_name_args, sub_node, local_templates)
      }
    end
    code << compile_body(body, local_templates).generate_xml_output_code(outvar, contextvar)
    code
  end

  def compile_body(node, local_templates)
    case node
    when HTree::Doc
      TemplateNode.new(node.children.map {|n| compile_body(n, local_templates) })
    when HTree::Elem
      ht_attrs = node.attributes.find_all {|name, text| template_attribute? name }
      ht_attrs = ht_attrs.sort_by {|htname, text| htname.universal_name }
      ignore_tag = false
      unless ht_attrs.empty?
        attr_mod = {}
        ht_attrs.each {|htname, text|
          attr_mod[htname] = nil
          if /\A_attr_/ =~ htname.local_name
            attr_mod[TemplateAttrName.new(htname.namespace_prefix, htname.namespace_uri, $')] = text
          end
        }
        ht_attrs.reject! {|htname, text| /\A_attr_/ =~ htname.local_name }
        node = node.subst_subnode(attr_mod)
        ignore_tag = IGNORABLE_ELEMENTS[node.name] && node.attributes.empty?
      end
      ht_names = ht_attrs.map {|htname, text| htname.universal_name }
      ht_vals =  ht_attrs.map {|htname, text| text.to_s }
      case ht_names
      when []
        compile_literal_elem(node, local_templates)
      when ['_text'] # <n _text="expr" />
        generate_logic_node(compile_dynamic_text(ignore_tag, ht_vals[0]), node, local_templates)
      when ['_if'] # <n _if="expr" >...</n>
        generate_logic_node(compile_if(ignore_tag, ht_vals[0], nil), node, local_templates)
      when ['_else', '_if'] # <n _if="expr" _else="expr.meth(args)" >...</n>
        generate_logic_node(compile_if(ignore_tag, ht_vals[1], ht_vals[0]), node, local_templates)
      when ['_call'] # <n _call="recv.meth(args)" />
        generate_logic_node(compile_call(ignore_tag, ht_vals[0]), node, local_templates)
      when ['_iter'] # <n _iter="expr.meth(args)//fargs" >...</n>
        generate_logic_node(compile_iter(ignore_tag, ht_vals[0]), node, local_templates)
      when ['_iter_children'] # <n _iter_children="expr.meth(args)//fargs" >...</n>
        generate_logic_node(compile_iter_children(ignore_tag, ht_vals[0]), node, local_templates)
      else
        raise HTree::Error, "unexpected template attributes: #{ht_attrs.inspect}"
      end
    else
      return node
    end
  end

  def compile_literal_elem(node, local_templates)
    subst = {}
    node.children.each_with_index {|n, i|
      subst[i] = compile_body(n, local_templates)
    }
    node.subst_subnode(subst)
  end

  def valid_syntax?(code)
    begin
      eval("BEGIN {return true}\n#{code.untaint}")
    rescue SyntaxError
      raise SyntaxError, "invalid code: #{code}"
    end
  end

  def check_syntax(code)
    unless valid_syntax?(code)
      raise HTree::Error, "invalid ruby code: #{code}"
    end
  end

  def compile_dynamic_text(ignore_tag, expr)
    check_syntax(expr)
    logic = [:text, expr]
    logic = [:tag, logic] unless ignore_tag
    logic
  end

  def compile_if(ignore_tag, expr, else_call)
    check_syntax(expr)
    then_logic = [:children]
    unless ignore_tag
      then_logic = [:tag, then_logic]
    end
    else_logic = nil
    if else_call
      else_logic = compile_call(true, else_call)
    end
    [:if, expr, then_logic, else_logic]
  end

  def split_args(spec)
    return spec, '' if /\)\z/ !~ spec
    i = spec.length - 1
    nest = 0
    begin
      raise HTree::Error, "unmatched paren: #{spec}" if i < 0
      case spec[i]
      when ?\)
        nest += 1
      when ?\(
        nest -= 1
      end
      i -= 1
    end while nest != 0
    i += 1
    return spec[0, i], spec[(i+1)...-1]
  end

  def compile_call(ignore_tag, spec)
    # spec : [recv.]meth[(args)]
    spec = spec.strip
    spec, args = split_args(spec)
    unless /#{ID_PAT}\z/o =~ spec
      raise HTree::Error, "invalid _call: #{spec}"
    end
    meth = $&
    spec = $`
    if /\A\s*\z/ =~ spec
      recv = nil
    elsif /\A\s*(.*)\.\z/ =~ spec
      recv = $1
    else
      raise HTree::Error, "invalid _call: #{spec}"
    end
    check_syntax(recv)
    check_syntax("#{recv}(#{args})")
    [:call, recv, meth, args]
  end

  def compile_iter(ignore_tag, spec)
    # spec: <n _iter="expr.meth[(args)]//fargs" >...</n>
    spec = spec.strip
    unless %r{\s*//\s*(#{ID_PAT}\s*(?:,\s*#{ID_PAT}\s*)*)?\z}o =~ spec
      raise HTree::Error, "invalid block arguments for _iter: #{meth_args}"
    end
    call = $`.strip
    fargs = $1.strip || ''
    check_syntax("#{call} {|#{fargs}| }")
    logic = [:children]
    unless ignore_tag
      logic = [:tag, logic]
    end
    [:iter, call, fargs, logic]
  end

  def compile_iter_children(ignore_tag, spec)
    # spec: <n _iter_children="expr.meth[(args)]//fargs" >...</n>
    spec = spec.strip
    unless %r{\s*//\s*(#{ID_PAT}\s*(?:,\s*#{ID_PAT}\s*)*)?\z}o =~ spec
      raise HTree::Error, "invalid block arguments for _iter: #{meth_args}"
    end
    call = $`.strip
    fargs = $1.strip || ''
    check_syntax("#{call} {|#{fargs}| }")
    logic = [:children]
    logic = [:iter, call, fargs, logic]
    unless ignore_tag
      logic = [:tag, logic]
    end
    logic
  end

  def generate_logic_node(logic, node, local_templates)
    # logic ::= [:if, expr, then_logic, else_logic]
    #         | [:iter, call, fargs, logic]
    #         | [:tag, logic]
    #         | [:text, expr]
    #         | [:call, expr, meth, args]
    #         | [:children]
    #         | [:empty]
    case logic.first
    when :empty
      nil
    when :children
      TemplateNode.new(node.children.map {|n| compile_body(n, local_templates) })
    when :text
      _, expr = logic
      TemplateNode.new(lambda {|out, context| out.output_dynamic_text expr })
    when :tag
      _, rest_logic = logic
      subst = {}
      node.children.each_index {|i| subst[i] = nil }
      subst[0] = TemplateNode.new(generate_logic_node(rest_logic, node, local_templates))
      node.subst_subnode(subst)
    when :if
      _, expr, then_logic, else_logic = logic
      children = [
        lambda {|out, context| out.output_logic_line "if (#{expr})" },
        generate_logic_node(then_logic, node, local_templates)
      ]
      if else_logic
        children.concat [
          lambda {|out, context| out.output_logic_line "else" },
          generate_logic_node(else_logic, node, local_templates)
        ]
      end
      children <<
        lambda {|out, context| out.output_logic_line "end" }
      TemplateNode.new(*children)
    when :iter
      _, call, fargs, rest_logic = logic
      TemplateNode.new(
        lambda {|out, context| out.output_logic_line "#{call} {|#{fargs}|" },
        generate_logic_node(rest_logic, node, local_templates),
        lambda {|out, context| out.output_logic_line "}" }
      )
    when :call
      _, recv, meth, args = logic
      TemplateNode.new(
        lambda {|out, context|
          as = [out.outvar, ", "]
          ns = context.namespaces.reject {|k, v| HTree::Context::DefaultNamespaces[k] == v }
          if ns.empty?
            as << out.contextvar
          else
            as << "#{out.contextvar}.subst_namespaces("
            sep = ''
            ns.each {|k, v|
              as << sep << (k ? k.dump : "nil") << '=>' << v.dump
              sep = ', '
            }
            as << ")"
          end
          unless args.empty?
            as << ", " << args
          end
          if recv
            out.output_logic_line "(#{recv})._ht_#{meth}(#{as.join('')})"
          else
            out.output_logic_line "#{meth}.call(#{as.join('')})"
          end
        }
      )
    else
      raise Exception, "[bug] invalid logic: #{logic.inspect}"
    end
  end

  class HTree::GenCode
    def output_dynamic_text(expr)
      flush_buffer
      @code << "#{@outvar}.output_dynamic_text((#{expr}))\n"
    end

    def output_dynamic_attvalue(expr)
      flush_buffer
      @code << "#{@outvar}.output_dynamic_attvalue((#{expr}))\n"
    end

    def output_logic_line(line)
      flush_buffer
      @code << line << "\n"
    end
  end

  class TemplateNode
    include HTree::Node

    def initialize(*children)
      @children = children.flatten.compact
    end

    def output(out, context)
      @children.each {|c|
        if c.respond_to? :call
          c.call(out, context)
        else
          c.output(out, context)
        end
      }
    end
  end

  class TemplateAttrName < HTree::Name
    def output_attribute(text, out, context)
      output(out, context)
      out.output_string '="'
      out.output_dynamic_attvalue(text.to_s)
      out.output_string '"'
    end
  end

end
