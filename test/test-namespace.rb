require 'test/unit'
require 'htree/tag'

class TestNamespace < Test::Unit::TestCase
  def assert_equal_exact(expected, actual, message=nil)
    full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
    assert_block(full_message) { expected.equal_exact? actual }
  end

  # <ppp:nnn xmlns:ppp="uuu">
  def test_prefixed
    stag = HTree::STag.new("ppp:nnn",
      [["xmlns:ppp", "uuu"], ["a", "x"], ["q:b", "y"], ["pp{uu}c", "z"]],
      HTree::DefaultContext.subst_namespaces({"q"=>"u"}))
    assert_equal("ppp:nnn", stag.element_name.qualified_name)
    assert_equal("{uuu}nnn", stag.element_name.universal_name)
    assert_equal("nnn", stag.element_name.local_name)
    assert_equal("uuu", stag.element_name.namespace_uri)
    assert_equal("ppp", stag.element_name.namespace_prefix)

    nsattrs = []; stag.each_namespace_attribute {|p, u| nsattrs << [p, u] }
    assert_equal(1, nsattrs.length)
    assert_equal(["ppp", "uuu"], nsattrs.shift)

    attrs = []; stag.each_attribute {|n,t| attrs << [n.namespace_uri,n.namespace_prefix,n.local_name,t.to_s] }
    assert_equal(3, attrs.length)
    assert_equal(['', nil, "a", "x"], attrs.shift)
    assert_equal(["u", "q", "b", "y"], attrs.shift)
    assert_equal(["uu", "pp", "c", "z"], attrs.shift)
  end

  # <nnn xmlns="uuu">
  def test_default_ns
    stag = HTree::STag.new("nnn",
      [["xmlns", "uuu"],
      ["a", "x"], ["q:b", "y"], ["pp{uu}c", "z"]],
      HTree::DefaultContext.subst_namespaces({"q"=>"u"}))

    assert_equal("nnn", stag.element_name.qualified_name)
    assert_equal("{uuu}nnn", stag.element_name.universal_name)
    assert_equal("nnn", stag.element_name.local_name)
    assert_equal("uuu", stag.element_name.namespace_uri)
    assert_equal(nil, stag.element_name.namespace_prefix)

    nsattrs = []; stag.each_namespace_attribute {|p, u| nsattrs << [p, u] }
    assert_equal(1, nsattrs.length)
    assert_equal([nil, "uuu"], nsattrs.shift)

    attrs = []; stag.each_attribute {|n,t| attrs << [n.namespace_uri,n.namespace_prefix,n.local_name,t.to_s] }
    assert_equal(3, attrs.length)
    assert_equal(['', nil, "a", "x"], attrs.shift)
    assert_equal(["u", "q", "b", "y"], attrs.shift)
    assert_equal(["uu", "pp", "c", "z"], attrs.shift)
  end

  # <nnn xmlns="">
  def test_no_default_ns
    [{"q"=>"u"}, {nil=>"uu", "q"=>"u"}].each {|inh|
      stag = HTree::STag.new("nnn",
        [["xmlns", ""], ["a", "x"], ["q:b", "y"], ["pp{uu}c", "z"]],
        HTree::DefaultContext.subst_namespaces(inh))
      assert_equal("nnn", stag.element_name.qualified_name)
      assert_equal("nnn", stag.element_name.universal_name)
      assert_equal("nnn", stag.element_name.local_name)
      assert_equal('', stag.element_name.namespace_uri)
      assert_equal(nil, stag.element_name.namespace_prefix)

      nsattrs = []; stag.each_namespace_attribute {|p, u| nsattrs << [p, u] }
      assert_equal(1, nsattrs.length)
      assert_equal([nil, ""], nsattrs.shift)

      attrs = []; stag.each_attribute {|n,t| attrs << [n.namespace_uri,n.namespace_prefix,n.local_name,t.to_s] }
      assert_equal(3, attrs.length)
      assert_equal(['', nil, "a", "x"], attrs.shift)
      assert_equal(["u", "q", "b", "y"], attrs.shift)
      assert_equal(["uu", "pp", "c", "z"], attrs.shift)
    }
  end

  # <nnn>
  def test_no_ns
    stag = HTree::STag.new("nnn",
      [["a", "x"], ["q:b", "y"], ["pp{uu}c", "z"]],
      HTree::DefaultContext.subst_namespaces({"q"=>"u"}))

    assert_equal("nnn", stag.element_name.qualified_name)
    assert_equal("nnn", stag.element_name.universal_name)
    assert_equal("nnn", stag.element_name.local_name)
    assert_equal('', stag.element_name.namespace_uri)
    assert_equal(nil, stag.element_name.namespace_prefix)

    nsattrs = []; stag.each_namespace_attribute {|p, u| nsattrs << [p, u] }
    assert_equal(0, nsattrs.length)

    attrs = []; stag.each_attribute {|n,t| attrs << [n.namespace_uri,n.namespace_prefix,n.local_name,t.to_s] }
    assert_equal(3, attrs.length)
    assert_equal(['', nil, "a", "x"], attrs.shift)
    assert_equal(["u", "q", "b", "y"], attrs.shift)
    assert_equal(["uu", "pp", "c", "z"], attrs.shift)
  end

  # internally allocated element without prefix
  def test_universal_name_to_be_default_namespace
    stag = HTree::STag.new("{uuu}nnn",
      [["a", "x"], ["q:b", "y"], ["pp{uu}c", "z"]],
      HTree::DefaultContext.subst_namespaces({"q"=>"u"}))
    assert_equal("nnn", stag.element_name.qualified_name)
    assert_equal("{uuu}nnn", stag.element_name.universal_name)
    assert_equal("nnn", stag.element_name.local_name)
    assert_equal("uuu", stag.element_name.namespace_uri)
    assert_equal(nil, stag.element_name.namespace_prefix)

    nsattrs = []; stag.each_namespace_attribute {|p, u| nsattrs << [p, u] }
    assert_equal(0, nsattrs.length)

    attrs = []; stag.each_attribute {|n,t| attrs << [n.namespace_uri,n.namespace_prefix,n.local_name,t.to_s] }
    assert_equal(3, attrs.length)
    assert_equal(['', nil, "a", "x"], attrs.shift)
    assert_equal(["u", "q", "b", "y"], attrs.shift)
    assert_equal(["uu", "pp", "c", "z"], attrs.shift)
  end

  def test_prefixed_universal_name
    stag = HTree::STag.new("ppp{uuu}nnn",
      [["a", "x"], ["q:b", "y"], ["pp{uu}c", "z"], ["q{uu}d", "w"]],
      HTree::DefaultContext.subst_namespaces({"q"=>"u"}))
    assert_equal("ppp:nnn", stag.element_name.qualified_name)
    assert_equal("{uuu}nnn", stag.element_name.universal_name)
    assert_equal("nnn", stag.element_name.local_name)
    assert_equal("uuu", stag.element_name.namespace_uri)
    assert_equal("ppp", stag.element_name.namespace_prefix)

    nsattrs = []; stag.each_namespace_attribute {|p, u| nsattrs << [p, u] }
    assert_equal(0, nsattrs.length)

    attrs = []; stag.each_attribute {|n,t| attrs << [n.namespace_uri,n.namespace_prefix,n.local_name,t.to_s] }
    assert_equal(4, attrs.length)
    assert_equal(['', nil, "a", "x"], attrs.shift)
    assert_equal(["u", "q", "b", "y"], attrs.shift)
    assert_equal(["uu", "pp", "c", "z"], attrs.shift)
    assert_equal(["uu", "q", "d", "w"], attrs.shift)
  end

end
