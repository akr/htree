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

  def test_elem_subst_outrange
    e1 = HTree("<r>abc</r>").root
    e2 = e1.subst_subnode(-1=>HTree('<x/>'), 1=>HTree('<y/>'))
    assert_equal(HTree('<r><x/>abc<y/></r>').root, e2)
  end

  def test_doc_subst_outrange
    d1 = HTree("<r>abc</r>")
    d2 = d1.subst_subnode(-1=>HTree('<x/>'), 1=>HTree('<y/>'))
    assert_equal(HTree('<x/><r>abc</r><y/>'), d2)
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

  def test_change_by_subst_itself
    l = HTree("<r>a</r>").make_loc
    l2 = l.get_subnode(0, 0).subst_itself('x')
    assert_equal(HTree::Text.new('x'), l2.to_node)
    assert_equal(HTree('<r>x</r>'), l2.top.to_node)
    l2 = l.get_subnode(0).subst_itself('xxx')
    assert_equal(HTree::Text.new('xxx'), l2.to_node)
    assert_equal(HTree('xxx'), l2.top.to_node)
  end

  def test_add_by_subst_itself
    l = HTree("<r>a</r>").make_loc
    l2 = l.get_subnode(0, 'x').subst_itself('y')
    assert_equal(HTree::Text.new('y'), l2.to_node)
    assert_equal(HTree('<r x="y">a</r>'), l2.top.to_node)
    l2 = l.get_subnode(0, 0).subst_itself('b')
    assert_equal(HTree::Text.new('b'), l2.to_node)
    assert_equal(HTree('<r>b</r>'), l2.top.to_node)
    xmldecl = HTree('<?xml version="1.0"?>').get_subnode(0)
    l2 = l.get_subnode(-1).subst_itself(xmldecl)
    assert_equal(0, l2.index)
    assert_equal(xmldecl, l2.to_node)
    assert_equal(HTree('<?xml version="1.0"?><r>a</r>'), l2.top.to_node)
    procins = HTree('<?xxx yyy?>').get_subnode(0)
    l2 = l.get_subnode(10).subst_itself(procins)
    assert_equal(1, l2.index)
    assert_equal(procins, l2.to_node)
    assert_equal(HTree('<r>a</r><?xxx yyy?>'), l2.top.to_node)
  end

  def test_del_by_subst_itself
    l = HTree("<r x='y'><x/>y<z/></r>").make_loc
    l2 = l.get_subnode(0, 'x').subst_itself(nil)
    assert_equal(nil, l2.to_node)
    assert_equal(HTree('<r><x/>y<z/></r>'), l2.top.to_node)
    l2 = l.get_subnode(0, 1).subst_itself(nil)
    assert_equal(HTree('<r x="y"><x/><z/></r>'), l2.top.to_node)
    l = HTree('<?xml version="1.0"?><r/>').make_loc
    l2 = l.get_subnode(0).subst_itself(nil)
    assert_equal(HTree('<r/>'), l2.top.to_node)
  end

  def test_subst
    l = HTree('<?xml version="1.0"?><r><x/><y/><z/></r>').make_loc
    assert_equal(HTree("<r>x<y>a</y><z k=v /></r>"),
      l.to_node.subst({
        l.get_subnode(0) => nil,
        l.get_subnode(1, 0) => 'x',
        l.get_subnode(1, 1, 0) => 'a',
        l.get_subnode(1, 2, 'k') => 'v'
      }))
  end

end
