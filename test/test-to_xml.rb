require 'test/unit'
require 'htree/tag'
require 'htree/container'
require 'htree/parse'
require 'htree/to_xml'
require 'htree/equality'

class TestGenerateXML < Test::Unit::TestCase
  def test_name
    assert_equal('n', HTree::Name.new(nil, 'u', 'n').generate_xml)
    assert_equal('p:n', HTree::Name.new('p', 'u', 'n').generate_xml)
    assert_equal('n', HTree::Name.new(nil, nil, 'n').generate_xml)
    assert_equal('xmlns', HTree::Name.new('xmlns', nil, nil).generate_xml)
    assert_equal('xmlns:n', HTree::Name.new('xmlns', nil, 'n').generate_xml)
  end

  def test_stag_generate_xml
    assert_equal('<name>',
      HTree::STag.new("name").generate_xml)
    assert_equal('<name />',
      HTree::STag.new("name", []).generate_emptytag_xml)

    assert_equal('<name a="b" />',
      HTree::STag.new("name", [["a", "b"]]).generate_emptytag_xml)
    assert_equal('<name a="&lt;&quot;\'&gt;" />',
      HTree::STag.new("name", [['a', '<"\'>']]).generate_emptytag_xml)

    assert_equal('<ppp:nnn xmlns="uuu&quot;b" />',
      HTree::STag.new("ppp:nnn", [["xmlns", "uuu\"b"]]).generate_emptytag_xml)
  end

  def test_stag_generate_etag_xml
    assert_equal('</nnn>', HTree::STag.new("nnn").generate_etag_xml)
  end

  def test_elem
    assert_equal('<b />',
      HTree::Elem.new!(HTree::STag.new('b')).generate_xml)
    assert_equal('<b></b>',
      HTree::Elem.new!(HTree::STag.new('b'), []).generate_xml)
    assert_equal('<a><b /><c /><d /></a>',
      HTree::Elem.new!(HTree::STag.new('a'), [
        HTree::Elem.new!(HTree::STag.new('b')),
        HTree::Elem.new!(HTree::STag.new('c')),
        HTree::Elem.new!(HTree::STag.new('d'))
        ]).generate_xml)
  end
end

class TestUpdateXMLNS < Test::Unit::TestCase
  def test_update_xmlns_empty
    assert_equal(
      [],
      HTree::STag.new('n', [], HTree::DefaultContext).update_xmlns(HTree::DefaultContext).attributes)
  end

  def test_update_xmlns_used
    assert_equal(
      [[HTree::Name.new('xmlns', nil, 'p'), HTree::Text.new('u')]],
      HTree::STag.new('p:n', [['xmlns:p', 'u']], HTree::DefaultContext).attributes)

    assert_equal(
      [[HTree::Name.new('xmlns', nil, 'p'), HTree::Text.new('u')]],
      HTree::STag.new('p:n', [['xmlns:p', 'u']], HTree::DefaultContext).update_xmlns(HTree::DefaultContext).attributes)

    assert_equal(
      [],
      HTree::STag.new('p:n', [['xmlns:p', 'u']], HTree::DefaultContext).update_xmlns(HTree::Context.new({'p'=>'u'})).attributes)

    assert_equal(
      [[HTree::Name.new('xmlns', nil, 'p'), HTree::Text.new('u')]],
      HTree::STag.new('p:n', [['xmlns:p', 'u']], HTree::DefaultContext).update_xmlns(HTree::Context.new({'p'=>'v'})).attributes)
  end

  def test_update_xmlns_not_used
    assert_equal(
      [[HTree::Name.new('xmlns', nil, 'p'), HTree::Text.new('u')]],
      HTree::STag.new('n', [['xmlns:p', 'u']], HTree::DefaultContext).attributes)

    assert_equal(
      [[HTree::Name.new('xmlns', nil, 'p'), HTree::Text.new('u')]],
      HTree::STag.new('n', [['xmlns:p', 'u']], HTree::DefaultContext).update_xmlns(HTree::DefaultContext).attributes)

    assert_equal(
      [],
      HTree::STag.new('n', [['xmlns:p', 'u']], HTree::DefaultContext).update_xmlns(HTree::Context.new({'p'=>'u'})).attributes)

    assert_equal(
      [[HTree::Name.new('xmlns', nil, 'p'), HTree::Text.new('u')]],
      HTree::STag.new('n', [['xmlns:p', 'u']], HTree::DefaultContext).update_xmlns(HTree::Context.new({'p'=>'v'})).attributes)
  end

  def test_update_xmlns_extra
    assert_equal(
      [],
      HTree::STag.new(HTree::Name.new('p', 'u', 'n'), [], HTree::DefaultContext).attributes)

    assert_equal(
      [[HTree::Name.new('xmlns', nil, 'p'), HTree::Text.new('u')]],
      HTree::STag.new(HTree::Name.new('p', 'u', 'n'), [], HTree::DefaultContext).update_xmlns(HTree::DefaultContext).attributes)

    assert_equal(
      [],
      HTree::STag.new(HTree::Name.new('p', 'u', 'n'), [], HTree::DefaultContext).update_xmlns(HTree::Context.new({'p'=>'u'})).attributes)

    assert_equal(
      [[HTree::Name.new('xmlns', nil, 'p'), HTree::Text.new('u')]],
      HTree::STag.new(HTree::Name.new('p', 'u', 'n'), [], HTree::DefaultContext).update_xmlns(HTree::Context.new({'p'=>'v'})).attributes)
  end
end

class TestUGenXML < Test::Unit::TestCase
  def test_procins_generate_xml
    t = HTree::ProcIns.new('x', nil)
    assert_equal('<?x?>', t.generate_xml)
  end
end
