require 'test/unit'
require 'htree/extract_text'
require 'htree/equality'

class TestExtractText < Test::Unit::TestCase
  def test_single
    n = HTree::Text.new('abc')
    assert_equal(n, n.extract_text)
  end

  def test_elem
    t = HTree::Text.new('abc')
    n = HTree::Elem.new('e', t)
    assert_equal(t, n.extract_text)
  end


end
