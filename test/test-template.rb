require 'test/unit'
require 'htree/template'

class TestText < Test::Unit::TestCase
  Decl = '<?xml version="1.0" encoding="US-ASCII"?>'

  def assert_xhtml(expected, template, message=nil)
    assert_equal(
      '<?xml version="1.0" encoding="US-ASCII"?>' +
      '<html xmlns="http://www.w3.org/1999/xhtml">' +
      expected +
      '</html>',
      HTree.expand_template(''){"<html>#{template}</html>"},
      message)
  end

  def test_text
    assert_xhtml('<e>1</e>', '<e _text=1>d</e>')
    assert_xhtml('1', '<span _text=1>d</span>')
    assert_xhtml('<span x="2">1</span>', '<span x=2 _text=1>d</span>')
  end

  def test_attr
    assert_xhtml('<e x="1">d</e>', '<e _attr_x=1>d</e>')
    assert_xhtml('<span x="1">d</span>', '<span _attr_x=1>d</span>')
  end

  def test_if
    assert_xhtml('<e>d</e>', '<e _if=true>d</e>')
    assert_xhtml('', '<e _if=false>d</e>')
    assert_xhtml('<f>dd</f>', '<e _if=false _else=m>d</e><f _template=m>dd</f>')

    assert_xhtml('d', '<span _if=true>d</span>')
  end

  def test_iter
    assert_xhtml('<o><i>1</i></o><o><i>2</i></o><o><i>3</i></o>',
      '<o _iter=[1,2,3].each//v><i _text=v /></o>')
    assert_xhtml('<i>1</i><i>2</i><i>3</i>',
      '<span _iter=[1,2,3].each//v><i _text=v /></span>')
  end

  def test_iter_content
    assert_xhtml('<o><i>1</i><i>2</i><i>3</i></o>',
      '<o _iter_content=[1,2,3].each//v><i _text=v /></o>')
    assert_xhtml('<i>1</i><i>2</i><i>3</i>',
      '<span _iter_content=[1,2,3].each//v><i _text=v /></span>')
  end

  def test_iter_local_template
    assert_xhtml('<o><i>1</i></o><o><i>2</i></o><o><i>3</i></o>',
      '<o _iter=[1,2,3].each//v><i _call=m /><i _template=m _text=v></i></o>')
  end

  def test_call
    assert_xhtml('<f>1</f>',
      '<e _call=m(1) /><f _template=m(v) _text=v></f>')
  end

  def test_file
    assert_equal(<<'End',
<?xml version="1.0" encoding="US-ASCII"?><html xmlns="http://www.w3.org/1999/xhtml">
  <title>aaa</title>
</html>
End
      HTree.expand_template("#{File.dirname __FILE__}/template.html", "aaa", ''))
  end
end
