require 'test/unit'
require 'htree/text'

class TestText < Test::Unit::TestCase
  def test_new
    assert_equal("abc&amp;amp;def", HTree::Text.new("abc&amp;def").rcdata)
  end

=begin
  def test_parse
    assert_equal("abc&amp;def", HTree::Text.parse("abc&amp;def").rcdata)
  end

  def test_to_s
    assert_equal("abc&def", HTree::Text.parse("abc&amp;def").to_s)
  end
=end

end
