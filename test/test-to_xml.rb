require 'test/unit'
require 'htree/tag'
require 'htree/container'

class TestToXML < Test::Unit::TestCase
  def test_name
    assert_equal('n', HTree::Name.new(false, 'u', 'n').to_xml)
    assert_equal('p:n', HTree::Name.new('p', 'u', 'n').to_xml)
    assert_raises(HTree::Name::Error) { HTree::Name.new(nil, 'u', 'n').to_xml }
    assert_equal('n', HTree::Name.new(nil, nil, 'n').to_xml)
    assert_equal('xmlns', HTree::Name.new('xmlns', nil, nil).to_xml)
    assert_equal('xmlns:n', HTree::Name.new('xmlns', nil, 'n').to_xml)
  end

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
      HTree::Elem.new!(HTree::STag.new('b')).to_xml)
    assert_equal('<b></b>',
      HTree::Elem.new!(HTree::STag.new('b'), []).to_xml)
    assert_equal('<a><b /><c /><d /></a>',
      HTree::Elem.new!(HTree::STag.new('a'), [
        HTree::Elem.new!(HTree::STag.new('b')),
        HTree::Elem.new!(HTree::STag.new('c')),
        HTree::Elem.new!(HTree::STag.new('d'))
        ]).to_xml)
  end
end
