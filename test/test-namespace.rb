require 'test/unit'
require 'htree/tag'

class TestNamespace < Test::Unit::TestCase
  # <ppp:nnn xmlns:ppp="uuu">
  def test_prefixed
    stag = HTree::STag.new("ppp:nnn", [["xmlns:ppp", "uuu"]])
    assert_equal("ppp:nnn", stag.qualified_name)
    assert_equal("{uuu}nnn", stag.universal_name)
    assert_equal("nnn", stag.local_name)
    assert_equal("uuu", stag.namespace_uri)
    assert_equal("ppp", stag.namespace_prefix)
  end

  # <nnn xmlns="uuu">
  def test_default_ns
    stag = HTree::STag.new("nnn", [["xmlns", "uuu"]])
    assert_equal("nnn", stag.qualified_name)
    assert_equal("{uuu}nnn", stag.universal_name)
    assert_equal("nnn", stag.local_name)
    assert_equal("uuu", stag.namespace_uri)
    assert_equal(nil, stag.namespace_prefix)
  end

  # <nnn xmlns="">
  def test_no_default_ns
    [{}, {""=>"uu"}].each {|inh|
      stag = HTree::STag.new("nnn", [["xmlns", ""]], inh)
      assert_equal("nnn", stag.qualified_name)
      assert_equal("nnn", stag.universal_name)
      assert_equal("nnn", stag.local_name)
      assert_equal(nil, stag.namespace_uri)
      assert_equal(nil, stag.namespace_prefix)
    }
  end

  # <nnn>
  def test_no_ns
    stag = HTree::STag.new("nnn")
    assert_equal("nnn", stag.qualified_name)
    assert_equal("nnn", stag.universal_name)
    assert_equal("nnn", stag.local_name)
    assert_equal(nil, stag.namespace_uri)
    assert_equal(nil, stag.namespace_prefix)
  end
end
