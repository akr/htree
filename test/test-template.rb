require 'test/unit'
require 'htree/template'

class TestText < Test::Unit::TestCase
  Decl = '<?xml version="1.0" encoding="US-ASCII"?>'

  def assert_xhtml(expected, template, message=nil)
    assert_equal(
      "<?xml version=\"1.0\" encoding=\"US-ASCII\"?>"+
      "<html xmlns=\"http://www.w3.org/1999/xhtml\">#{expected}</html>",
      HTree.expand_template('US-ASCII', ''){"<html>#{template}</html>"},
      message)
  end

  def test_text
    assert_xhtml('<e>1</e>', '<e _text=1>d</e>')
  end

  def test_attr
    assert_xhtml('<e x="1">d</e>', '<e _attr_x=1>d</e>')
  end

  def test_if
    assert_xhtml('<e>d</e>', '<e _if=true>d</e>')
    assert_xhtml('', '<e _if=false>d</e>')
    assert_xhtml('<f>dd</f>',
      '<e _if=false _else=m>d</e><f _template=m>dd</f>')
  end

  def test_iter
    assert_xhtml('<o><i>1</i></o><o><i>2</i></o><o><i>3</i></o>',
      '<o _iter=[1,2,3].each//v><i _text=v /></o>')
  end

  def test_iter_content
    assert_xhtml('<o><i>1</i><i>2</i><i>3</i></o>',
      '<o _iter_content=[1,2,3].each//v><i _text=v /></o>')
  end

  def test_call
    assert_xhtml('<f>1</f>',
      '<e _call=m(1) /><f _template=m(v) _text=v></f>')
  end

  def test_span
    assert_xhtml('1', '<span _text=1>d</span>')
  end

end
