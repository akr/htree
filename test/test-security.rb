require 'test/unit'
require 'htree/parse'
require 'htree/template'
require 'pathname'

class TestSecurity < Test::Unit::TestCase
  def safe(n)
    assert_equal(0, $SAFE)
    Thread.new {
      $SAFE = n
      assert_equal(n, $SAFE)
      yield
    }.join
    assert_equal(0, $SAFE)
  end

  def test_parse
    safe(1) {
      assert_equal(1, $SAFE)
      assert_nothing_raised { HTree.parse("") }
      assert_raise(SecurityError) { HTree.parse("".taint) }
    }
    assert_nothing_raised { HTree.parse("") }
    assert_nothing_raised { HTree.parse("".taint) }
  end

  def test_template
    safe(1) {
      assert_nothing_raised { HTree.expand_template("/dev/null", nil, '') }
      assert_raise(SecurityError) { HTree.expand_template("/dev/null".taint, nil, '') }
    }
    assert_nothing_raised { HTree.expand_template("/dev/null", nil, '') }
    assert_nothing_raised { HTree.expand_template("/dev/null".taint, nil, '') }
  end

end

