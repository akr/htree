require 'test/unit'
require 'htree/loc'
require 'htree/parse'

class TestLoc < Test::Unit::TestCase
  def test_make_loc
    t = HTree.parse('<?xml version="1.0"?><!DOCTYPE root><root>a<?x y?><!-- c --></boo>')
    assert_instance_of(HTree::Doc::Loc, t.make_loc)
    assert_instance_of(HTree::XMLDecl::Loc, t.children[0].make_loc)
    assert_instance_of(HTree::DocType::Loc, t.children[1].make_loc)
    assert_instance_of(HTree::Elem::Loc, t.children[2].make_loc)
    assert_instance_of(HTree::Text::Loc, t.children[2].children[0].make_loc)
    assert_instance_of(HTree::ProcIns::Loc, t.children[2].children[1].make_loc)
    assert_instance_of(HTree::Comment::Loc, t.children[2].children[2].make_loc)
    assert_instance_of(HTree::BogusETag::Loc, t.children[2].children[3].make_loc)
    assert_equal(nil, t.make_loc.parent)
    assert_equal(nil, t.make_loc.index)
  end

  def test_get_subnode
    t = HTree.parse('<?xml version="1.0"?><!DOCTYPE root><root>a<?x y?><!-- c --></boo>')
    l = t.make_loc
    assert_instance_of(HTree::Doc::Loc, l)
    assert_instance_of(HTree::Location, l.get_subnode(-1))
    assert_instance_of(HTree::XMLDecl::Loc, l.get_subnode(0))
    assert_instance_of(HTree::DocType::Loc, l.get_subnode(1))
    assert_instance_of(HTree::Elem::Loc, l2 = l.get_subnode(2))
    assert_instance_of(HTree::Location, l.get_subnode(3))
    assert_instance_of(HTree::Location, l2.get_subnode(-1))
    assert_instance_of(HTree::Location, l2.get_subnode('attr'))
    assert_instance_of(HTree::Text::Loc, l2.get_subnode(0))
    assert_instance_of(HTree::ProcIns::Loc, l2.get_subnode(1))
    assert_instance_of(HTree::Comment::Loc, l2.get_subnode(2))
    assert_instance_of(HTree::BogusETag::Loc, l2.get_subnode(3))
    assert_instance_of(HTree::Location, l2.get_subnode(4))
    assert_same(l.get_subnode(0), l.get_subnode(0))
  end

  def test_find_loc_step
    t = HTree.parse('<a><b>x<!---->y</a><c/><a/>')
    assert_equal('a[1]', t.find_loc_step(0))
    assert_equal('c', t.find_loc_step(1))
    assert_equal('a[2]', t.find_loc_step(2))
    t = t.children[0]
    assert_equal('b', t.find_loc_step(0))
    t = t.children[0]
    assert_equal('text()[1]', t.find_loc_step(0))
    assert_equal('comment()', t.find_loc_step(1))
    assert_equal('text()[2]', t.find_loc_step(2))
  end

  def test_path
    l = HTree.parse('<a><b>x</b><b/><a/>').make_loc
    l2 = l.get_subnode(0, 0, 0)
    assert_equal('doc()', l.path)
    assert_equal('doc()/a/b[1]/text()', l2.path)
  end

end
