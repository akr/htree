require 'test/unit'
require 'htree/template'

class TestText < Test::Unit::TestCase
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
  end
end
