require 'test/unit'
require 'htree/traverse'
require 'htree/parse'
require 'htree/equality'

class TestTraverse < Test::Unit::TestCase
  def test_filter
    l = HTree.parse('<a><b>x</b><b/><a/>').make_loc
    l2 = l.filter {|n| n.path != 'doc()/a/b[1]' }
    assert_equal(HTree.parse('<a><b/><a/>'), l2)
  end

  def test_title
    t = HTree.parse('<html><title>aaa</title>')
    assert_equal('aaa', t.title)
  end

  def test_author
    t = HTree.parse('<html><meta name=author content=xxx>')
    assert_equal('xxx', t.author)
  end
end
