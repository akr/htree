require 'test/unit'
require 'htree/template'
require 'stringio'

class TestTemplate < Test::Unit::TestCase
  Decl = '<?xml version="1.0" encoding="US-ASCII"?>'

  def assert_xhtml(expected, template, message=nil)
    prefix = '<?xml version="1.0" encoding="US-ASCII"?>' +
             "<html xmlns=\"http://www.w3.org/1999/xhtml\"\n>"
    suffix = "</html\n>"
    result = HTree.expand_template(''){"<html>#{template}</html>"}
    assert_match(/\A#{Regexp.quote prefix}/, result)
    assert_match(/#{Regexp.quote suffix}\z/, result)
    result = result[prefix.length..(-suffix.length-1)]
    assert_equal(expected, result, message)
  end

  def test_text
    assert_xhtml("<e\n>1</e\n>", '<e _text=1>d</e>')
    assert_xhtml('1', '<span _text=1>d</span>')
    assert_xhtml("<span x=\"2\"\n>1</span\n>", '<span x=2 _text=1>d</span>')
  end

  def test_attr
    assert_xhtml("<e x=\"1\"\n>d</e\n>", '<e _attr_x=1>d</e>')
    assert_xhtml("<span x=\"1\"\n>d</span\n>", '<span _attr_x=1>d</span>')
    assert_xhtml("<span x=\"&quot;\"\n>d</span\n>", '<span _attr_x=\'"\x22"\'>d</span>')
  end

  def test_if
    assert_xhtml("<e\n>d</e\n>", '<e _if=true>d</e>')
    assert_xhtml('', '<e _if=false>d</e>')
    assert_xhtml("<f\n>dd</f\n>", '<e _if=false _else=m>d</e><f _template=m>dd</f>')

    assert_xhtml('d', '<span _if=true>d</span>')
  end

  def test_iter
    assert_xhtml("<o\n><i\n>1</i\n></o\n><o\n><i\n>2</i\n></o\n><o\n><i\n>3</i\n></o\n>",
      '<o _iter=[1,2,3].each//v><i _text=v /></o>')
    assert_xhtml("<i\n>1</i\n><i\n>2</i\n><i\n>3</i\n>",
      '<span _iter=[1,2,3].each//v><i _text=v /></span>')
  end

  def test_iter_content
    assert_xhtml("<o\n><i\n>1</i\n><i\n>2</i\n><i\n>3</i\n></o\n>",
      '<o _iter_content=[1,2,3].each//v><i _text=v /></o>')
    assert_xhtml("<i\n>1</i\n><i\n>2</i\n><i\n>3</i\n>",
      '<span _iter_content=[1,2,3].each//v><i _text=v /></span>')
  end

  def test_iter_local_template
    assert_xhtml("<o\n><i\n>1</i\n></o\n><o\n><i\n>2</i\n></o\n><o\n><i\n>3</i\n></o\n>",
      '<o _iter=[1,2,3].each//v><i _call=m /><i _template=m _text=v></i></o>')
  end

  def test_call
    assert_xhtml("<f\n>1</f\n>",
      '<e _call=m(1) /><f _template=m(v) _text=v></f>')
  end

  def test_template
    assert_xhtml('d',
      '<span _template="span()">d</span><e _call="span()"></e>')
  end

  def test_file
    assert_equal(<<'End'.chop,
<?xml version="1.0" encoding="US-ASCII"?><html xmlns="http://www.w3.org/1999/xhtml"
><title
>aaa</title
></html
>
End
      HTree.expand_template("#{File.dirname __FILE__}/template.html", "aaa", ''))
  end

  def test_whitespace
    assert_xhtml("<x\n></x\n>", '<x> </x>')
    assert_xhtml("<x\n>&#32;</x\n>", '<x>&#32;</x>')
    assert_xhtml("<pre\n> </pre\n>", '<pre> </pre>')
    assert_xhtml(" ", %q{<span _text="' '"> </span>})
    assert_xhtml(" ", %q{<span _text="' '"/>})
  end

  def test_ignorable
    assert_xhtml("<div\n>a</div\n>", '<div>a</div>')
    assert_xhtml("<span\n>a</span\n>", '<span>a</span>')
  end

  def test_template_in_attr
    assert_xhtml("<a x=\"1\"\n></a\n>", '<a _attr_x=1><b _template=m></b></a>')
  end

  def test_empty_block_argument
    assert_xhtml("vv", '<span _iter="2.times//">v</span>')
  end

  def test_empty_element
    assert_xhtml("<elem\n/>", '<elem />') # 2004-06-10: reported by Takuo KITAME
    assert_xhtml("<elem x=\"1\"\n/>", '<elem _attr_x=1 />')
    assert_xhtml("<elem\n></elem\n>", '<elem _text=\'""\' />')
    assert_xhtml("<elem\n/>", '<elem _if="true" />')
    assert_xhtml("", '<elem _if="false" />')
    assert_xhtml("<foo\n/>", '<elem _if="false" _else="foo"/><foo _template="foo"/>')
    assert_xhtml("<elem\n/><elem\n/>", '<elem _iter="2.times//" />')
    assert_xhtml("<elem\n></elem\n>", '<elem _iter_content="2.times//" />')
  end

  def test_empty_element_start_end_tag
    assert_xhtml("<elem\n></elem\n>", '<elem></elem>')
    assert_xhtml("<elem x=\"1\"\n></elem\n>", '<elem _attr_x=1 ></elem>')
    assert_xhtml("<elem\n></elem\n>", '<elem _text=\'""\' ></elem>')
    assert_xhtml("<elem\n></elem\n>", '<elem _if="true" ></elem>')
    assert_xhtml("", '<elem _if="false" ></elem>')
    assert_xhtml("<foo\n></foo\n>", '<elem _if="false" _else="foo"></elem><foo _template="foo"></foo>')
    assert_xhtml("<elem\n></elem\n><elem\n></elem\n>", '<elem _iter="2.times//" ></elem>')
    assert_xhtml("<elem\n></elem\n>", '<elem _iter_content="2.times//" ></elem>')
  end

  def test_toplevel_local_variable
    eval("htree_test_toplevel_local_variable = :non_modified_value", TOPLEVEL_BINDING)
    HTree.expand_template("#{File.dirname __FILE__}/assign.html", "aaa", '')
    assert_equal(:non_modified_value, eval("htree_test_toplevel_local_variable", TOPLEVEL_BINDING))
    eval("htree_test_toplevel_local_variable = 1", TOPLEVEL_BINDING)
  end

  def test_extend_compiled_template
    m = HTree.compile_template('<div _template="m">self is <span _text="inspect"></span></div>')
    o = "zzz"
    o.extend m
    assert_equal('<?xml version="1.0" encoding="US-ASCII"?>self is "zzz"',
      HTree.expand_template(''){'<div _call="o.m"></div>'})
  end

  def test_attr_nbsp
    @t = HTree::Text.parse_pcdata('&nbsp;')
    assert_xhtml("<span x=\"&nbsp;\"\n>d</span\n>", '<span _attr_x="@t">d</span>')
  end

  def test_text_nbsp
    @t = HTree::Text.parse_pcdata('&nbsp;')
    assert_xhtml("&nbsp;", '<span _text="@t">d</span>')
  end

end

class MemFile
  def initialize(str)
    @str = str
  end

  def read
    @str
  end
end

class TestTemplateScopeObj
  Const = 'good_const'
  @@cvar = 'good_cvar'
  def initialize
    @ivar = 'good_ivar'
  end
end

class TestTemplateScope < Test::Unit::TestCase
  Const = 'bad_const'
  @@cvar = 'bad_cvar'
  def setup
    @ivar = 'bad_ivar'
    eval("test_local_variable = 'bad_lvar'", TOPLEVEL_BINDING)
  end

  XMLDeclStr = '<?xml version="1.0" encoding="US-ASCII"?>'

  def test_expand_template
    obj = TestTemplateScopeObj.new
    assert_equal("#{XMLDeclStr}[TestTemplateScopeObj]",
      HTree.expand_template(MemFile.new('<span _text="Module.nesting.inspect"/>'), obj, ''))
    assert_equal("#{XMLDeclStr}good_ivar",
      HTree.expand_template(MemFile.new('<span _text="@ivar"/>'), obj, ''))
    assert_equal("#{XMLDeclStr}good_cvar",
      HTree.expand_template(MemFile.new('<span _text="@@cvar"/>'), obj, ''))
    assert_equal("#{XMLDeclStr}good_const",
      HTree.expand_template(MemFile.new('<span _text="Const"/>'), obj, ''))
    test_local_variable = 'bad_lvar'
    assert_equal("#{XMLDeclStr}good_lvar",
      HTree.expand_template(MemFile.new('<span _text="begin test_local_variable rescue NameError; \'good_lvar\' end"/>'), obj, ''))
  end

  def test_compile_template
    obj = TestTemplateScopeObj.new
    mod = HTree.compile_template(MemFile.new(<<-'End'))
      <span _template=test_nesting _text="Module.nesting.inspect"/>
      <span _template=test_const _text="Const"/>
      <span _template=test_cvar _text="@@cvar"/>
      <span _template=test_ivar _text="@ivar"/>
    End
    mod.module_eval <<-'End'
      Const = 'mod_const'
      @@cvar = 'mod_cvar'
      @ivar = 'mod_ivar'
    End
    assert_equal("[#{mod.inspect}]", mod.test_nesting.extract_text.to_s)
    assert_equal("mod_const", mod.test_const.extract_text.to_s)
    assert_equal("mod_cvar", mod.test_cvar.extract_text.to_s)
    assert_equal("mod_ivar", mod.test_ivar.extract_text.to_s)
    obj = Object.new
    obj.instance_variable_set :@ivar, 'obj_ivar'
    obj.extend mod
    assert_equal("[#{mod.inspect}]", obj.__send__(:test_nesting).extract_text.to_s)
    assert_equal("mod_const", obj.__send__(:test_const).extract_text.to_s)
    assert_equal("mod_cvar", obj.__send__(:test_cvar).extract_text.to_s)
    assert_equal("obj_ivar", obj.__send__(:test_ivar).extract_text.to_s)
  end
end
