require 'test/unit'
require 'htree/leaf'

class TestProcIns < Test::Unit::TestCase
  def test_initialize
    assert_raises(HTree::ProcIns::Error) { HTree::ProcIns.new!('target', "?>") }
  end

  def test_new
    assert_equal('? >', HTree::ProcIns.new('target', "?>").content)
  end
end

class TestComment < Test::Unit::TestCase
  def test_initialize
    assert_raises(HTree::Comment::Error) { HTree::Comment.new!("a--b") }
    assert_raises(HTree::Comment::Error) { HTree::Comment.new!("a-") }
  end

  def test_new
    assert_equal('a- -b', HTree::Comment.new("a--b").content)
    assert_equal('a- ', HTree::Comment.new("a-").content)
  end
end
