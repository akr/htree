require 'test/unit'
require 'htree/parse'
require 'htree/equality'

class TestParse < Test::Unit::TestCase
  def test_empty
    assert_equal(HTree::Doc.new([]), HTree.parse("").eliminate_raw_string)
  end

  def test_xmlns_default
    t1 = HTree::Doc.new([
           HTree::Elem.new!(
             HTree::STag.new('x1', [['xmlns', 'bb']],
               {'xml'=>'http://www.w3.org/XML/1998/namespace'}),
             [HTree::Elem.new!(HTree::STag.new('x2', [],
                                {nil => 'bb', 'xml'=>'http://www.w3.org/XML/1998/namespace'}), [])])
         ])
    t2 = HTree.parse('<x1 xmlns="bb"><x2>')
    assert_equal(t1, t2)
  end
end
