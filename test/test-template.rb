require 'test/unit'
require 'htree/template'

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

end
