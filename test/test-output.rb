require 'test/unit'
require 'htree'

class TestOutput < Test::Unit::TestCase
  def gen(t, meth=:output, *rest)
    encoder = HTree::Encoder.new('US-ASCII', 'US-ASCII')
    t.__send__(meth, *(rest + [encoder, HTree::DefaultContext]))
    encoder.finish
  end

  def test_text
    assert_equal('a&amp;&lt;&gt;"b', gen(HTree::Text.new('a&<>"b')))

    assert_equal("abc&amp;def", gen(HTree::Text.new("abc&def")))
    assert_equal('"\'&amp;', gen(HTree::Text.new('"\'&')))
    assert_equal('"\'&lt;&amp;&gt;', gen(HTree::Text.new('"\'<&>')))
  end

  def test_text_attvalue
    assert_equal('"a&amp;&lt;&gt;&quot;b"', gen(HTree::Text.new('a&<>"b'), :output_attvalue))

    assert_equal('"abc"', gen(HTree::Text.new("abc"), :output_attvalue))
    assert_equal('"&quot;"', gen(HTree::Text.new('"'), :output_attvalue))
  end

  def test_name
    assert_equal('abc', gen(HTree::Name.parse_element_name('abc', HTree::DefaultContext)))
    assert_equal('n', gen(HTree::Name.new(nil, 'u', 'n')))
    assert_equal('p:n', gen(HTree::Name.new('p', 'u', 'n')))
    assert_equal('n', gen(HTree::Name.new(nil, '', 'n')))
    assert_equal('xmlns', gen(HTree::Name.new('xmlns', nil, nil)))
    assert_equal('xmlns:n', gen(HTree::Name.new('xmlns', nil, 'n')))
  end

  def test_name_attribute
    assert_equal('abc="a&amp;&lt;&gt;&quot;b"',
      gen(HTree::Name.parse_element_name('abc', HTree::DefaultContext),
          :output_attribute,
          HTree::Text.new('a&<>"b')))
  end

  def test_doc
    t = HTree::Doc.new(HTree::Elem.new('a'), HTree::Elem.new('b'))
    assert_equal("<a\n/><b\n/>", gen(t))
  end

  def test_elem
    t = HTree::Elem.new('a', [])
    assert_equal("<a\n></a\n>", gen(t))

    assert_equal("<b\n/>",
      gen(HTree::Elem.new!(HTree::STag.new('b'))))
    assert_equal("<b\n></b\n>",
      gen(HTree::Elem.new!(HTree::STag.new('b'), [])))
    assert_equal("<a\n><b\n/><c\n/><d\n/></a\n>",
      gen(HTree::Elem.new!(HTree::STag.new('a'), [
            HTree::Elem.new!(HTree::STag.new('b')),
            HTree::Elem.new!(HTree::STag.new('c')),
            HTree::Elem.new!(HTree::STag.new('d'))
            ])))
  end

  def test_elem_empty
    t = HTree::Elem.new('a')
    assert_equal("<a\n/>", gen(t))
  end

  def test_stag
    assert_equal("<name\n>",
      gen(HTree::STag.new("name"), :output_stag))
    assert_equal("<name\n/>",
      gen(HTree::STag.new("name"), :output_emptytag))
    assert_equal("</name\n>",
      gen(HTree::STag.new("name"), :output_etag))
      
    assert_equal("<name a=\"b\"\n/>",
      gen(HTree::STag.new("name", [["a", "b"]]), :output_emptytag))
    assert_equal("<name a=\"&lt;&quot;\'&gt;\"\n/>",
      gen(HTree::STag.new("name", [['a', '<"\'>']]), :output_emptytag))
      
    assert_equal("<ppp:nnn xmlns=\"uuu&quot;b\"\n/>",
      gen(HTree::STag.new("ppp:nnn", [["xmlns", "uuu\"b"]]), :output_emptytag))
  end

  def test_xmldecl
    t = HTree::XMLDecl.new('1.0', 'US-ASCII')
    assert_equal('', gen(t))
    assert_equal('<?xml version="1.0" encoding="US-ASCII"?>',
      gen(t, :output_prolog_xmldecl))
  end

  def test_doctype
    t = HTree::DocType.new('html',
      '-//W3C//DTD HTML 4.01//EN',
      'http://www.w3.org/TR/html4/strict.dtd')
    assert_equal('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">', gen(t))
  end

  def test_procins
    t = HTree::ProcIns.new('xml-stylesheet', 'type="text/xml" href="#style1"')
    assert_equal('<?xml-stylesheet type="text/xml" href="#style1"?>', gen(t))
    t = HTree::ProcIns.new('x', nil)
    assert_equal('<?x?>', gen(t))
  end

  def test_comment
    t = HTree::Comment.new('xxx')
    assert_equal('<!--xxx-->', gen(t))
  end

end

class TestHTMLOutput < Test::Unit::TestCase
  def test_top_xmlns
    assert_equal("<html\n>aaa</html\n>", HTree("<html>aaa").display_html(""))
  end

  def test_script
    assert_equal("<html\n><script\n>a < b</script\n></html\n>",
      HTree("<html><script>a < b").display_html(""))
  end

  def test_script_invalid_content
    assert_raise(ArgumentError) {
      HTree("<html><script>a </ b").display_html("")
    }
  end

  def test_br
    assert_equal("<html\n>a<br\n>b<br\n>c</html\n>",
      HTree("<html>a<br>b<br>c").display_html(""))
  end
end
