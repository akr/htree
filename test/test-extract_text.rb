require 'test/unit'
require 'htree/extract_text'

class TestExtractText < Test::Unit::TestCase
  def test_single
    n = HTree::Text.new('abc')
    assert_equal(n, n.extract_text)
  end


end
