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
    s = '<script><a></script><a>'
    assert_equal([
      [:stag, '<script>'],
      [:text_cdata_content, '<a>'],
      [:etag, '</script>'],
      [:stag, '<a>'],
    ], scan(s))

    s = '<script><a>'
    assert_equal([
      [:stag, '<script>'],
      [:text_cdata_content, '<a>'],
    ], scan(s))
  end

end
