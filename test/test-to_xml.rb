require 'test/unit'
require 'htree/tag'
require 'htree/container'

class TestToXML < Test::Unit::TestCase
  def test_stag_to_xml
    assert_equal('<name>',
      HTree::STag.new("name").to_xml)
    assert_equal('<name />',
      HTree::STag.new("name", []).to_emptytag_xml)

    assert_equal('<name a="b" />',
      HTree::STag.new("name", [["a", "b"]]).to_emptytag_xml)
    assert_equal('<name a="&lt;&quot;\'&gt;" />',
      HTree::STag.new("name", [['a', '<"\'>']]).to_emptytag_xml)

    assert_equal('<ppp:nnn xmlns="uuu&quot;b" />',
      HTree::STag.new("ppp:nnn", [["xmlns", "uuu\"b"]]).to_emptytag_xml)
  end

  def test_stag_to_etag_xml
    assert_equal('</nnn>', HTree::STag.new("nnn").to_etag_xml)
  end

  def test_elem
    assert_equal('<b />',
      HTree::Elem.new(HTree::STag.new('b')).to_xml)
    assert_equal('<b></b>',
      HTree::Elem.new(HTree::STag.new('b'), []).to_xml)
    assert_equal('<a><b /><c /><d /></a>',
      HTree::Elem.new(HTree::STag.new('a'), [
        HTree::Elem.new(HTree::STag.new('b')),
        HTree::Elem.new(HTree::STag.new('c')),
        HTree::Elem.new(HTree::STag.new('d'))
        ]).to_xml)
  end
end
