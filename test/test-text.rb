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

  def test_to_xml
    assert_equal("abc&amp;def", HTree::Text.new("abc&def").to_xml)
    assert_equal('"\'&amp;', HTree::Text.new('"\'&').to_xml)
    assert_equal('"\'&lt;&amp;&gt;', HTree::Text.new('"\'<&>').to_xml)
  end

  def test_to_xml_attvalue
    assert_equal('"abc"', HTree::Text.new("abc").to_xml_attvalue)
    assert_equal('"&quot;"', HTree::Text.new('"').to_xml_attvalue)
  end

end
