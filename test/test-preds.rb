require 'test/unit'
require 'htree/preds'
require 'htree/loc'
require 'htree/parse'

class TestPreds < Test::Unit::TestCase
  def pred(t)
    [
      t.doc?,
      t.elem?,
      t.text?,
      t.xmldecl?,
      t.doctype?,
      t.procins?,
      t.comment?,
      t.bogusetag?
    ]
  end

  def test_pred
    t = HTree.parse('<?xml version="1.0"?><!DOCTYPE root><root>a<?x y?><!-- c --></boo>')
    #             doc?   elem?  text?  xmldecl?      procins?      bogusetag?
    #                                         doctype?      comment?
    assert_equal([true , false, false, false, false, false, false, false], pred(t))
    assert_equal([true , false, false, false, false, false, false, false], pred(t.make_loc))
    s = t.get_subnode(0)
    assert_equal([false, false, false, true , false, false, false, false], pred(s))
    assert_equal([false, false, false, true , false, false, false, false], pred(s.make_loc))
    s = t.get_subnode(1)
    assert_equal([false, false, false, false, true , false, false, false], pred(s))
    assert_equal([false, false, false, false, true , false, false, false], pred(s.make_loc))
    s = t.get_subnode(2)
    assert_equal([false, true , false, false, false, false, false, false], pred(s))
    assert_equal([false, true , false, false, false, false, false, false], pred(s.make_loc))

    s = t.get_subnode(2, 0)
    assert_equal([false, false, true , false, false, false, false, false], pred(s))
    assert_equal([false, false, true , false, false, false, false, false], pred(s.make_loc))
    s = t.get_subnode(2, 1)
    assert_equal([false, false, false, false, false, true , false, false], pred(s))
    assert_equal([false, false, false, false, false, true , false, false], pred(s.make_loc))
    s = t.get_subnode(2, 2)
    assert_equal([false, false, false, false, false, false, true , false], pred(s))
    assert_equal([false, false, false, false, false, false, true , false], pred(s.make_loc))
    s = t.get_subnode(2, 3)
    assert_equal([false, false, false, false, false, false, false, true ], pred(s))
    assert_equal([false, false, false, false, false, false, false, true ], pred(s.make_loc))
  end
end
