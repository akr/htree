require 'test/unit'
require 'htree'

class TestRawString < Test::Unit::TestCase
  def test_elem
    t = HTree.parse("<a>x</a>")
    assert_equal("<a>x</a>", t.root.raw_string)
    assert_equal("<a>x</a>", t.root.raw_string) # raw_string shouldn't have side effect.
  end

  def test_no_raw_string
    t = HTree::Elem.new('a')
    assert_equal(nil, t.raw_string)
    t = HTree::Elem.new('a', HTree.parse("<a>x</a>").root)
    assert_equal(nil, t.raw_string)
  end
end
