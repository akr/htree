# = Template Engine
#
# == Template Syntax
#
# The htree template engine converts HTML and some data to XHTML.
# A template directive is described as special HTML attribute which name
# begins with underscore.
#
# The template directives are listed as follows.
#
# - <elem \_attr_<i>name</i>="<i>expr</i>">content</elem>
# - <elem _text="<i>expr</i>">dummy-content</elem>
# - <elem _if="<i>expr</i>" _else="<i>mod.name(args)</i>">then-content</elem>
# - <elem _iter="<i>expr.meth(args)//vars</i>">content</elem>
# - <elem _iter_content="<i>expr.meth(args)//vars</i>">content</elem>
# - <elem _call="<i>mod.name(args)</i>">dummy-content</elem>
# - <elem _template="<i>name(vars)</i>">body</elem>
#
# === Template Semantics
#
# - attribute substitution
#   - <elem \_attr_<i>name</i>="<i>expr</i>">content</elem>
#
#   \_attr_<i>name</i> is used for a dynamic attribute.
#
#        <elem _attr_xxx="..."/>
#     -> <elem xxx="..."/>
# 
#   It is expanded to <i>name</i>="content".
#   The content is escaped form of a value of _expr_.
#
#   \_attr_<i>name</i> can be used multiple times in single element.
#
# - text substitution
#   - <elem _text="<i>expr</i>">dummy-content</elem>
#
#   _text substitutes content of the element by the string
#   evaluated from _expr_.
#   If the element is span or div, and there is no other attributes,
#   no tags are produced.
#
#        <elem _text="...">dummy-content</elem>
#     -> <elem>...</elem>
#
# - conditional
#   - <elem _if="<i>expr</i>">then-content</elem>
#   - <elem _if="<i>expr</i>" _else="<i>name(args)</i>">then-content</elem>
#
#   _if is used for conditional.
#
#   If <i>expr</i> is evaluated to true, it expands as follows
#   regardless of existence of _else.
#
#        <elem _if="<i>expr</i>">then-content</elem>
#     -> <elem>then-content</elem>
#
#   If <i>expr</i> is evaluated to false, it expands using _else.
#   If _else is not given, it expands to empty.
#   If _else is given, it expands as follows.
#
#        <elem _if="<i>expr</i>" _else="<i>name(args)</i>">then-content</elem>
#     -> <elem _call="<i>name(args)</i>">then-content</elem>
#     -> see _call for further expansion.
#
#   It is expanded to <elem>then-content</elem> if _expr_ is evaluated to
#   a true value.
#   Otherwise, it is replaced by other template specified by _else attribute.
#   If _else attribute is not given, it just replaced by empty.
#
# - iteration
#   - <elem _iter="<i>expr.meth(args)//vars</i>">content</elem>
#   - <elem _iter_content="<i>expr.meth(args)//vars</i>">content</elem>
#
#   _iter and _iter_content is used for iteration.
#   _iter iterates the element itself but _iter_content iterates the content.
#
#        <outer _iter="..."><inner/></outer>
#     -> <outer><inner/></outer><outer><inner/></outer>...
#
#        <outer _iter_content="..."><inner/></outer>
#     -> <outer><inner/><inner/>...</outer>
#
#   <i>expr.meth(args)</i> specifies iterator method call.
#   It is actually called with a block.
#   The block have block parameters <i>vars</i>.
#   <i>vars</i> must be variables separated by comma.
#
# - template call
#   - <elem _call="<i>name(args)</i>">dummy-content</elem>
#   - <elem _call="<i>mod.name(args)</i>">dummy-content</elem>
#   
#   _call is used to expand a template function.
#   The template function is defined by _template.
#
#        <d _template="m">...</d>
#        <c _call="m">...</c>
#     -> <d>...</d>
#
#   A local template can be called as follows:
#
#     HTree.expand_template{<<'End'}
#     <a _template=ruby_talk(num)
#        _attr_href='"http://ruby-talk.org/#{num}"'
#        >[ruby-talk:<span _text=num>nnn</span>]</a>
#     Ruby 1.8.0 is released at <span _call=ruby_talk(77946) />.
#     Ruby 1.8.1 is released at <span _call=ruby_talk(88814) />.
#     End
#
#   <i>mod</i> should be the result of HTree.compile_template.
#
#     M = HTree.compile_template(<<'End')
#     <a _template=ruby_talk(num)
#        _attr_href='"http://ruby-talk.org/#{num}"'
#        >[ruby-talk:<span _text=num>nnn</span>]</a>
#     End
#     HTree.expand_template{<<'End'}
#     <html>
#     Ruby 1.8.0 is released at <span _call=M.ruby_talk(77946) />.
#     Ruby 1.8.1 is released at <span _call=M.ruby_talk(88814) />.
#     </html>
#     End
#
#   The module can included.
#   In such case, the template function can be called without <i>mod.</i>
#   prefix.
#
#     include HTree.compile_template(<<'End')
#     <a _template=ruby_talk(num)
#        _attr_href='"http://ruby-talk.org/#{num}"'
#        >[ruby-talk:<span _text=num>nnn</span>]</a>
#     End
#     HTree.expand_template{<<'End'}
#     <html>
#     Ruby 1.8.0 is released at <span _call=ruby_talk(77946) />.
#     Ruby 1.8.1 is released at <span _call=ruby_talk(88814) />.
#     </html>
#     End
#
# - template definition
#   - <elem _template="<i>name(vars)</i>">body</elem>
#
#   _template defines a template function which is usable by _call.
#
#   When a template is compiled to a module by HTree.compile_template,
#   the module have a module function for each template function
#   defined by outermost _template attribute.
#
# === White Space Handling
#
# The htree template engine strips whitespace text nodes in a template
# except under HTML pre element.
#
# For example the white space text node between two spans in following template is stripped.
#
#   <span _text="'a'"/> <span _text="'b'"/> -> "ab"
#
# Character entity references are not stripped.
#
#   <span _text="'a'"/>&#32;<span _text="'b'"/> -> "a&#32;b"
# 
# Text nodes generated by _text is not stripped.
# 
#   <span _text="'a'"/><span _text="' '"> </span><span _text="'b'"/> -> "a b"
# 
# == Method Summary
#
# - HTree.expand_template(<i>template_pathname</i>) -> $stdout
# - HTree.expand_template(<i>template_pathname</i>, <i>obj</i>) -> $stdout
# - HTree.expand_template(<i>template_pathname</i>, <i>obj</i>, <i>out</i>) -> <i>out</i>
# - HTree.expand_template(<i>template_pathname</i>, <i>obj</i>, <i>out</i>, <i>encoding</i>) -> <i>out</i>
#
# - HTree.expand_template{<i>template_string</i>} -> $stdout
# - HTree.expand_template(<i>out</i>) {<i>template_string</i>} -> <i>out</i>
# - HTree.expand_template(<i>out</i>, <i>encoding</i>) {<i>template_string</i>} -> <i>out</i>
#
# - HTree.compile_template(<i>template_string</i>) -> Module
# - HTree{<i>template_string</i>} -> HTree::Doc
# - HTree(<i>html_string</i>) -> HTree::Doc
#
# == Design Decision on Design/Logic Separation
#
# HTree template engine doesn't force you to separate design and logic.
# Any logic (Ruby code) can be embedded in design (HTML).
#
# However the template engine cares the separation by logic refactorings.
# The logic is easy to move between a template and an application.
# For example, following tangled template
#
#   tmpl.html:
#     <html>
#       <head>
#         <title _text="very-complex-ruby-code">dummy</title>
#       </head>
#       ...
#     </html>
#
#   app.rb:
#     HTree.expand_template('tmpl.html', obj)
#
# can be refactored as follows.
#
#   tmpl.html:
#     <html>
#       <head>
#         <title _text="title">dummy</title>
#       </head>
#       ...
#     </html>
#
#   app.rb:
#     def obj.title
#       very-complex-ruby-code
#     end
#     HTree.expand_template('tmpl.html', obj)
# 
# In general, any expression in a template can be refactored to an application
# by extracting it as a method.
# In JSP, this is difficult especially for a code fragment of an iteration.
#
# Also HTree encourages to separate business logic (Ruby code in an application)
# and presentation logic (Ruby code in a template).
# For example, presentation logic to color table rows stripe
# can be embedded in a template.
# It doesn't need to tangle an application. 
#

require 'htree/parse'
require 'htree/gencode'
require 'htree/equality'
require 'htree/traverse'

# <code>HTree.expand_template</code> expands a template.
#
# The arguments should be specified as follows.
# All argument except <i>pathname</i> are optional.
#
# - HTree.expand_template(<i>pathname</i>, <i>obj</i>, <i>out</i>, <i>encoding</i>) -> <i>out</i>
# - HTree.expand_template(<i>out</i>, <i>encoding</i>) {<i>template_string</i>} -> <i>out</i>
#
# The template is specified by a file or a string.
# If a block is not given, the first argument represent a template pathname.
# Otherwise, the block is yielded and its value is interpreted as a template
# string.
# So it can be called as follows in simplest case.
#
# - HTree.expand_template(<i>template_pathname</i>)
# - HTree.expand_template{<i>template_string</i>}
#
# Ruby expressions in the template file specified by _template_pathname_ are
# evaluated in the context of the optional second argument <i>obj</i> as follows.
# I.e. the pseudo variable self in the expressions is bound to <i>obj</i>.
#
#   HTree.expand_template(template_pathname, obj)
#
# Ruby expressions in the template_string are evaluated
# in the context of the caller of HTree.expand_template.
# (binding information is specified by the block.)
# I.e. they can access local variables etc.
# We recommend to specify template_string as a literal string without
# interpolation because dynamically generated string may break lexical scope.
#
# HTree.expand_template has two more optional arguments:
# <i>out</i>, <i>encoding</i>.
#
# <i>out</i> specifies output target.
# It should have <tt><<</tt> method: IO and String for example.
# If it is not specified, $stdout is used.
# 
# <i>encoding</i> specifies output character encoding.
# If it is not specified, internal encoding is used.
#
# HTree.expand_template returns <i>out</i> or $stdout if <i>out</i> is not
# specified.
#
def HTree.expand_template(*args, &block)
  if block
    template = block.call
    binding = block
  else
    pathname = args.shift
    obj = args.shift
    if pathname.respond_to? :read
      template = pathname.read.untaint
      if template.respond_to? :charset
        template = Iconv.conv(HTree::Encoder.internal_charset, template.charset, template)
      end
    else
      template = File.read(pathname).untaint
    end
    binding = eval("lambda {|context_object| context_object.instance_eval 'binding'}", TOPLEVEL_BINDING).call(obj)
  end

  out = args.shift || $stdout
  encoding = args.shift || HTree::Encoder.internal_charset
  if !args.empty?
    raise ArgumentError, "wrong number of arguments" 
  end
  HTree::TemplateCompiler.new.expand_template(template, out, encoding, binding)
end

# <code>HTree(<i>html_string</i>)</code> parses <i>html_string</i>.
# <code>HTree{<i>template_string</i>}</code> parses <i>template_string</i> and expand it as a template.
# Ruby expressions in <i>template_string</i> is evaluated in the scope of the caller.
#
# <code>HTree()</code> and <code>HTree{}</code> returns a tree as an instance of HTree::Doc.
def HTree(html_string=nil, &block)
  if block_given?
    raise ArgumentError, "both argument and block given." if html_string
    template = block.call
    HTree.parse(HTree::TemplateCompiler.new.expand_fragment_template(template, '', HTree::Encoder.internal_charset, block))
  else
    HTree.parse(html_string)
  end
end

# <code>HTree.compile_template(<i>template_string</i>)</code> compiles
# <i>template_string</i> as a template.
#
# HTree.compile_template returns a module.
# The module has module functions for each templates defined in
# <i>template_string</i>.
# The returned module can be used for +include+.
#
#  M = HTree.compile_template(<<'End')
#  <p _template=birthday(subj,t)>
#  <span _text=subj />'s birthday is <span _text="t.strftime('%B %dth %Y')"/>.</p>
#  End
#  M.birthday('Ruby', Time.utc(1993, 2, 24)).display_xml
#  # <p xmlns="http://www.w3.org/1999/xhtml">Ruby's birthday is February 24th 1993.</p>
#
# The module function takes arguments specifies by a <code>_template</code>
# attribute and returns a tree represented as HTree::Node.
#
def HTree.compile_template(template_string)
  code = HTree::TemplateCompiler.new.compile_template(template_string)
  eval(code)
end

# :stopdoc:

class HTree::TemplateCompiler
  IGNORABLE_ELEMENTS = {
    'span' => true,
    'div' => true,
    '{http://www.w3.org/1999/xhtml}span' => true,
    '{http://www.w3.org/1999/xhtml}div' => true,
  }

  def initialize
    @gensym_id = 0
  end

  def gensym(suffix='')
    @gensym_id += 1
    "g#{@gensym_id}#{suffix}"
  end

  def parse_template(template)
    strip_whitespaces(HTree.parse(template))
  end

  WhiteSpacePreservingElements = {
    '{http://www.w3.org/1999/xhtml}pre' => true
  }

  def strip_whitespaces(template)
    case template
    when HTree::Doc
      HTree::Doc.new(*template.children.map {|c| strip_whitespaces(c) }.compact)
    when HTree::Elem, HTree::Doc
      return template if WhiteSpacePreservingElements[template.name]
      subst = {}
      template.children.each_with_index {|c, i|
        subst[i] = strip_whitespaces(c)
      }
      template.subst_subnode(subst)
    when HTree::Text
      if /\A[ \t\r\n]*\z/ =~ template.rcdata
        nil
      else
        template
      end
    else
      template
    end
  end

  def expand_template(template, out, encoding, binding)
    template = parse_template(template)
    outvar = gensym('out')
    contextvar = gensym('top_context')
    code = <<"End"
#{outvar} = HTree::Encoder.new(#{encoding.dump})
#{contextvar} = HTree::DefaultContext
#{compile_body(outvar, contextvar, template, false)}\
#{outvar}.finish_with_xmldecl
End
    result = eval(code, binding)
    out << result
    out
  end

  def expand_fragment_template(template, out, encoding, binding)
    template = parse_template(template)
    outvar = gensym('out')
    contextvar = gensym('top_context')
    code = <<"End"
#{outvar} = HTree::Encoder.new(#{encoding.dump})
#{contextvar} = HTree::DefaultContext
#{compile_body(outvar, contextvar, template, false)}\
#{outvar}.finish
End
    result = eval(code, binding)
    out << result
    out
  end

  def compile_template(src)
    srcdoc = parse_template(src)
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
      if ht_attrs.empty?
        subst = {}
        node.children.each_with_index {|n, i|
          subst[i] = extract_templates(n, templates, is_toplevel)
        }
        node.subst_subnode(subst)
      else
        ht_attrs.each {|htname, text|
          if htname.universal_name == '_template'
            name_fargs = text.to_s
            templates << [name_fargs, node.subst_subnode('_template' => nil)]
            return nil
          end
        }
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
#{compile_body(outvar, contextvar, node, false)}\
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
#{compile_body(outvar, contextvar, node, false, local_templates)}\
}
End
  end

  def compile_body(outvar, contextvar, node, is_toplevel, local_templates={})
    if node.elem? && IGNORABLE_ELEMENTS[node.name] && node.attributes.empty?
      node = TemplateNode.new(node.children)
    else
      node = TemplateNode.new(node)
    end
    generate_logic_node([:content], node, local_templates).generate_xml_output_code(outvar, contextvar)
  end

  def compile_node(node, local_templates)
    case node
    when HTree::Doc
      TemplateNode.new(node.children.map {|n| compile_node(n, local_templates) })
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
        generate_logic_node([:tag, [:content]], node, local_templates)
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
      when ['_iter_content'] # <n _iter_content="expr.meth(args)//fargs" >...</n>
        generate_logic_node(compile_iter_content(ignore_tag, ht_vals[0]), node, local_templates)
      else
        raise HTree::Error, "unexpected template attributes: #{ht_attrs.inspect}"
      end
    else
      return node
    end
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
    then_logic = [:content]
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
      raise HTree::Error, "invalid block arguments for _iter: #{spec}"
    end
    call = $`.strip
    fargs = $1.strip || ''
    check_syntax("#{call} {|#{fargs}| }")
    logic = [:content]
    unless ignore_tag
      logic = [:tag, logic]
    end
    [:iter, call, fargs, logic]
  end

  def compile_iter_content(ignore_tag, spec)
    # spec: <n _iter_content="expr.meth[(args)]//fargs" >...</n>
    spec = spec.strip
    unless %r{\s*//\s*(#{ID_PAT}\s*(?:,\s*#{ID_PAT}\s*)*)?\z}o =~ spec
      raise HTree::Error, "invalid block arguments for _iter: #{spec}"
    end
    call = $`.strip
    fargs = $1.strip || ''
    check_syntax("#{call} {|#{fargs}| }")
    logic = [:content]
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
    #         | [:content]
    #         | [:empty]
    case logic.first
    when :empty
      nil
    when :content
      subtemplates = []
      children = []
      node.children.each {|c|
        children << extract_templates(c, subtemplates, false)
      }
      if subtemplates.empty?
        TemplateNode.new(node.children.map {|n|
          compile_node(n, local_templates)
        })
      else
        local_templates = local_templates.dup
        decl = ''
        subtemplates.each {|sub_name_args, sub_node|
          sub_name = sub_name_args[ID_PAT]
          local_templates[sub_name] = sub_name
          decl << "#{sub_name} = "
        }
        decl << "nil\n"
        defs = []
        subtemplates.each {|sub_name_args, sub_node|
          defs << lambda {|out, context|
            out.output_logic_line compile_local_template(sub_name_args, sub_node, local_templates)
          }
        }
        TemplateNode.new(
          lambda {|out, context| out.output_logic_line decl },
          defs,
          children.map {|n| compile_node(n, local_templates) }
        )
      end
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
          elsif local_templates.include? meth
            out.output_logic_line "#{meth}.call(#{as.join('')})"
          else
            out.output_logic_line "_ht_#{meth}(#{as.join('')})"
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
    attr_reader :children

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

# :startdoc:
