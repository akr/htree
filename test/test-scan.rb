require 'test/unit'
require 'htree/scan'

class TestScan < Test::Unit::TestCase
  def scan(str)
    result = []
    HTree.scan(str) {|e| result << e }
    result
  end

  def test_empty
    assert_equal([], scan(''))
  end

  def t_single(s)
    n = yield
    assert_equal([n], scan(s))
  end

  def test_single
    s = '<?xml version="1.0"?>'
    assert_equal([[:xmldecl, s]], scan(s))

    s = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
    assert_equal([[:doctype, s]], scan(s))

    s = '<?xxx yyy?>'
    assert_equal([[:procins, s]], scan(s))

    s = '<a>'
    assert_equal([[:stag, s]], scan(s))
    s = '</a>'
    assert_equal([[:etag, s]], scan(s))
    s = '<a/>'
    assert_equal([[:emptytag, s]], scan(s))
    s = '<!-- abc -->'
    assert_equal([[:comment, s]], scan(s))
    s = '<![CDATA[abc]]>'
    assert_equal([[:text_cdata_section, s]], scan(s))
    s = 'abc'
    assert_equal([[:text_pcdata, s]], scan(s))
  end

  def test_xmldecl_seen
    s0 = '<?xml version="1.0"?>'
    s1 = '<A>'
    assert_equal([[:stag, s1]], scan(s1))
    assert_equal([[:xmldecl, s0], [:stag, s1]], scan(s0 + s1))
  end

  def test_cdata_content
    s = '<html><script><a></script><a>'
    assert_equal([
      [:stag, '<html>'],
      [:stag, '<script>'],
      [:text_cdata_content, '<a>'],
      [:etag, '</script>'],
      [:stag, '<a>'],
    ], scan(s))

    s = '<html><script><a>'
    assert_equal([
      [:stag, '<html>'],
      [:stag, '<script>'],
      [:text_cdata_content, '<a>'],
    ], scan(s))
  end

  def test_text
    s = 'a<e>b<e>c<e>d'
    assert_equal([
      [:text_pcdata, 'a'],
      [:stag, '<e>'],
      [:text_pcdata, 'b'],
      [:stag, '<e>'],
      [:text_pcdata, 'c'],
      [:stag, '<e>'],
      [:text_pcdata, 'd'],
    ], scan(s))
  end

  def test_eol_html
    # In SGML, a line break just after start tag and
    # a line break just before end tag is ignored.
    # http://www.w3.org/TR/REC-html40/appendix/notes.html#notes-line-breaks
    #
    # But usual browser including mozilla doesn't.
    # So HTree doesn't ignore them and treat as usual text.
    s = "<html>a\n<e>\nb\n<f>\nc\n</f>\nd\n</e>\ne"
    assert_equal([
      [:stag, "<html>"],
      [:text_pcdata, "a\n"],
      [:stag, "<e>"],
      [:text_pcdata, "\nb\n"],
      [:stag, "<f>"],
      [:text_pcdata, "\nc\n"],
      [:etag, "</f>"],
      [:text_pcdata, "\nd\n"],
      [:etag, "</e>"],
      [:text_pcdata, "\ne"],
    ], scan(s))

    s = "<html>a\n<e>\nb\n<script>\nc\n</script>\nd\n</e>\ne"
    assert_equal([
      [:stag, "<html>"],
      [:text_pcdata, "a\n"],
      [:stag, "<e>"],
      [:text_pcdata, "\nb\n"],
      [:stag, "<script>"],
      [:text_cdata_content, "\nc\n"],
      [:etag, "</script>"],
      [:text_pcdata, "\nd\n"],
      [:etag, "</e>"],
      [:text_pcdata, "\ne"],
    ], scan(s))

  end

  def test_eol_xml
    # In XML, line breaks are treated as part of content.
    # It's because KEEPRSRE is yes in XML.
    # http://www.satoshii.org/markup/websgml/valid-xml#keeprsre
    s = "<?xml version='1.0'?>a\n<e>\nb\n<f>\nc\n</f>\nd\n</e>\ne"
    assert_equal([
      [:xmldecl, "<?xml version='1.0'?>"],
      [:text_pcdata, "a\n"],
      [:stag, "<e>"],
      [:text_pcdata, "\nb\n"],
      [:stag, "<f>"],
      [:text_pcdata, "\nc\n"],
      [:etag, "</f>"],
      [:text_pcdata, "\nd\n"],
      [:etag, "</e>"],
      [:text_pcdata, "\ne"],
    ], scan(s))
  end

  def test_xml_html_detection
    assert_equal([false, true], HTree.scan("<html></html>") {})
    assert_equal([true, false], HTree.scan("<rss></rss>") {})
    assert_equal([true, true], HTree.scan('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">') {})
  end

end
