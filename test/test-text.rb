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

  def kcode(kc)
    old = $KCODE
    begin
      $KCODE = kc
      yield
    ensure
      $KCODE = old
    end
  end

  def test_normalize
    kcode('EUC') {
      assert_equal("<ABC&#38;&#38;&#160;\xa6\xc1",
        HTree::Text.new!("&lt;&#65;&#x42;C&amp;&#38;&nbsp;&alpha;").normalized_rcdata)
    }
  end
end
