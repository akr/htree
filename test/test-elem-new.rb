require 'test/unit'
require 'htree/container'
require 'htree/equality'

class TestElemNew < Test::Unit::TestCase
  def test_empty
    e = HTree::Elem.new('a')
    assert_equal('a', e.stag.qualified_name)
    assert_equal([], e.stag.attributes)
    assert_equal({}, e.stag.inherited_namespaces)
    assert_nil(e.children)
    assert_nil(e.etag)
  end

  def test_empty_array
    e = HTree::Elem.new('a', [])
    assert_equal('a', e.stag.qualified_name)
    assert_equal([], e.stag.attributes)
    assert_equal({}, e.stag.inherited_namespaces)
    assert_equal([], e.children)
    assert_equal('a', e.etag.qualified_name)
  end

  def test_node
    t = HTree::Text.new('t')
    e = HTree::Elem.new('a', t)
    assert_equal([], e.stag.attributes)
    assert_equal([t], e.children)
  end

  def test_hash
    t = HTree::Text.new('t')
    e = HTree::Elem.new('a', {'b' => t})
    assert_equal([['b', t]], e.stag.attributes.map {|n,v| [n.universal_name, v] })
    assert_equal([], e.children)
  end

  def test_string
    t = HTree::Text.new('s')
    e = HTree::Elem.new('a', "s")
    assert_equal([], e.stag.attributes)
    assert_equal([t], e.children)
  end

  def test_interleave
    t = HTree::Text.new('t')
    e = HTree::Elem.new('a', t, {'b' => t}, t, {'c' => 'd'}, t)
    assert_equal([['b', t], ['c', HTree::Text.new('d')]], e.stag.attributes.map {|n,v| [n.universal_name, v] })
    assert_equal([t, t, t], e.children)
  end

  def test_nest
    t = HTree::Text.new('t')
    e = HTree::Elem.new('a', [t, t, t])
    assert_equal([], e.stag.attributes)
    assert_equal([t, t, t], e.children)
  end

end
