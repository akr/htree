require 'test/unit'
require 'htree/elem'
require 'htree/display'

class TestXMLNS < Test::Unit::TestCase
  def assert_xml(expected, node)
    assert_equal(expected, node.display_xml('', 'US-ASCII'))
  end

  def test_update_xmlns_empty
    assert_xml("<n\n/>", HTree::Elem.new('n'))
  end

  def test_reduce_xmlns
    assert_xml(
      "<p:n xmlns:p=\"u\"\n/>",
      HTree::Elem.new('p:n', {'xmlns:p'=>'u'}))

    assert_xml(
      "<n xmlns:p=\"u\"\n><p:n\n/></n\n>",
      HTree::Elem.new('n', {'xmlns:p'=>'u'}, HTree::Elem.new('p:n', {'xmlns:p'=>'u'})))

    assert_xml(
      "<n xmlns:p=\"u\"\n><p:n xmlns:p=\"v\"\n/></n\n>",
      HTree::Elem.new('n', {'xmlns:p'=>'u'}, HTree::Elem.new('p:n', {'xmlns:p'=>'v'})))
  end

  def test_extra_xmlns
    assert_xml(
      "<p:n xmlns:p=\"u\"\n/>",
      HTree::Elem.new(HTree::Name.new('p', 'u', 'n')))

    assert_xml(
      "<nn\n><p:n xmlns:p=\"u\"\n/></nn\n>",
      HTree::Elem.new('nn', HTree::Elem.new(HTree::Name.new('p', 'u', 'n'))))

    assert_xml(
      "<nn xmlns:p=\"u\"\n><p:n\n/></nn\n>",
      HTree::Elem.new('nn', {'xmlns:p'=>'u'}, HTree::Elem.new(HTree::Name.new('p', 'u', 'n'))))

    assert_xml(
      "<nn xmlns:p=\"v\"\n><p:n xmlns:p=\"u\"\n/></nn\n>",
      HTree::Elem.new('nn', {'xmlns:p'=>'v'}, HTree::Elem.new(HTree::Name.new('p', 'u', 'n'))))
  end
end
