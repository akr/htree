require 'test/unit'
require 'htree'

class TestExtractText < Test::Unit::TestCase
  def test_elem_raw_string
    t = HTree.parse("<a>x</a>")
    assert_equal("<a>x</a>", t.root.raw_string)
    assert_equal("<a>x</a>", t.root.raw_string) # raw_string shouldn't have side effect.
  end
end
