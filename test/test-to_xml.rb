require 'test/unit'
require 'htree/elem'
require 'htree/to_xml'

class TestXMLNS < Test::Unit::TestCase
  def test_update_xmlns_empty
    assert_equal('<n />', HTree::Elem.new('n').to_xml)
  end

  def test_reduce_xmlns
    assert_equal(
      '<p:n xmlns:p="u" />',
      HTree::Elem.new('p:n', {'xmlns:p'=>'u'}).to_xml)

    assert_equal(
      '<n xmlns:p="u"><p:n /></n>',
      HTree::Elem.new('n', {'xmlns:p'=>'u'}, HTree::Elem.new('p:n', {'xmlns:p'=>'u'})).to_xml)

    assert_equal(
      '<n xmlns:p="u"><p:n xmlns:p="v" /></n>',
      HTree::Elem.new('n', {'xmlns:p'=>'u'}, HTree::Elem.new('p:n', {'xmlns:p'=>'v'})).to_xml)
  end

  def test_extra_xmlns
    assert_equal(
      '<p:n xmlns:p="u" />',
      HTree::Elem.new(HTree::Name.new('p', 'u', 'n')).to_xml)

    assert_equal(
      '<nn><p:n xmlns:p="u" /></nn>',
      HTree::Elem.new('nn', HTree::Elem.new(HTree::Name.new('p', 'u', 'n'))).to_xml)

    assert_equal(
      '<nn xmlns:p="u"><p:n /></nn>',
      HTree::Elem.new('nn', {'xmlns:p'=>'u'}, HTree::Elem.new(HTree::Name.new('p', 'u', 'n'))).to_xml)

    assert_equal(
      '<nn xmlns:p="v"><p:n xmlns:p="u" /></nn>',
      HTree::Elem.new('nn', {'xmlns:p'=>'v'}, HTree::Elem.new(HTree::Name.new('p', 'u', 'n'))).to_xml)
  end
end
