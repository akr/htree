require 'test/unit'
require 'htree'

class TestSubnode < Test::Unit::TestCase
  def test_elem_get
    e1 = HTree.parse("<a href=x>abc</a>").root
    assert_equal(HTree::Text.new("x"), e1.get_subnode("href"))
    assert_equal(HTree::Text.new("abc"), e1.get_subnode(0))
  end

  def test_elem_subst
    e1 = HTree.parse_xml("<a href=x>abc</a>").root
    e2 = e1.subst_subnode("href"=>"xxx", 0=>"def")
    assert_equal("a", e2.name)
    assert_equal("xxx", e2.fetch_attr("href"))
    assert_equal([HTree::Text.new("def")], e2.children)
    assert_equal([], e1.subst_subnode(0=>nil).children)
  end

  def test_elem_subst_empty
    e1 = HTree.parse("<img />").root
    assert_equal(true, e1.empty_element?)
    assert_equal(true, e1.subst_subnode("src"=>"xxx").empty_element?)
    assert_equal(false, e1.subst_subnode(0=>"xxx").empty_element?)
  end

  def test_elem_multiple_attr_value
    h = {"b"=>"c", HTree::Name.new(nil, "", "b")=>"d"}
    assert_match(/\A(cd|dc)\z/,
      HTree::Elem.new("a").subst_subnode(h).get_subnode('b').to_s)

    a = [["b","c"], [HTree::Name.new(nil, "", "b"),"d"]]
    assert_equal('cd',
      HTree::Elem.new("a").subst_subnode(a).get_subnode('b').to_s)
    assert_equal('dc',
      HTree::Elem.new("a").subst_subnode(a.reverse).get_subnode('b').to_s)
  end

  def test_doc_get
    doc = HTree.parse("<?xml?><a href=x>abc</a> ")
    assert_equal(doc.root, doc.get_subnode(1))
  end

  def test_doc_subst
    doc1 = HTree.parse("<?xml?><a href=x>abc</a> ")

    doc2 = doc1.subst_subnode(1=>"yy")
    assert_equal(HTree::Text.new("yy"), doc2.children[1])
    assert_equal([], doc1.subst_subnode(0=>nil, 1=>nil, 2=>nil).children)
  end

  def test_doc_loc
    d1 = HTree.parse("<r>a</r>")
    d2 = HTree.parse("<q/>")
    assert_equal(d2, d1.subst_subnode(0=>d2.make_loc))
  end

  def test_doc
    e = HTree.parse("<r>a</r>").root
    d = HTree.parse("<?xml version='1.0'?><!DOCTYPE q><q/>")
    r = HTree('<r><q/></r>').root
    assert_equal(r, e.subst_subnode(0=>d))
    assert_equal(r, e.subst_subnode(0=>d.make_loc))
    assert_equal(r, e.subst_subnode(0=>[d]))
    assert_equal(r, e.subst_subnode(0=>[d.make_loc]))
  end

  def test_doc2
    e = HTree.parse("<r>a</r>")
    d = HTree.parse("<?xml version='1.0'?><!DOCTYPE q><q/>")
    r = HTree('<q/>')
    assert_equal(r, e.subst_subnode(0=>d))
    assert_equal(r, e.subst_subnode(0=>d.make_loc))
    assert_equal(r, e.subst_subnode(0=>[d]))
    assert_equal(r, e.subst_subnode(0=>[d.make_loc]))
  end

end
