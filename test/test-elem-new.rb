require 'test/unit'
require 'htree/doc'
require 'htree/elem'
require 'htree/equality'
require 'htree/traverse'

class TestElemNew < Test::Unit::TestCase
  def test_empty
    e = HTree::Elem.new('a')
    assert_equal('a', e.qualified_name)
    assert_equal({}, e.attributes)
    assert_equal(HTree::DefaultContext, e.instance_variable_get(:@stag).inherited_context)
    assert_equal([], e.children)
    assert_equal(true, e.empty_element?)
    assert_nil(e.instance_variable_get(:@etag))
  end

  def test_empty_array
    e = HTree::Elem.new('a', [])
    assert_equal('a', e.qualified_name)
    assert_equal({}, e.attributes)
    assert_equal(HTree::DefaultContext, e.instance_variable_get(:@stag).inherited_context)
    assert_equal([], e.children)
    assert_equal(false, e.empty_element?)
    assert_equal(nil, e.instance_variable_get(:@etag))
  end

  def test_empty_attr
    e = HTree::Elem.new('a', {'href'=>'xxx'})
    assert_equal('a', e.qualified_name)
    assert_equal({HTree::Name.parse_attribute_name('href', HTree::DefaultContext)=>HTree::Text.new('xxx')}, e.attributes)
    assert_equal(HTree::DefaultContext, e.instance_variable_get(:@stag).inherited_context)
    assert_equal([], e.children)
    assert_equal(true, e.empty_element?)
    assert_equal(nil, e.instance_variable_get(:@etag))
  end

  def test_node
    t = HTree::Text.new('t')
    e = HTree::Elem.new('a', t)
    assert_equal({}, e.attributes)
    assert_equal([t], e.children)
  end

  def test_hash
    t = HTree::Text.new('t')
    e = HTree::Elem.new('a', {'b' => t})
    assert_equal([['b', t]], e.attributes.map {|n,v| [n.universal_name, v] })
    assert_equal([], e.children)
  end

  def test_string
    t = HTree::Text.new('s')
    e = HTree::Elem.new('a', "s")
    assert_equal({}, e.attributes)
    assert_equal([t], e.children)
  end

  def test_interleave
    t = HTree::Text.new('t')
    e = HTree::Elem.new('a', t, {'b' => t}, t, {'c' => 'd'}, t)
    assert_equal([['b', t], ['c', HTree::Text.new('d')]],
      e.attributes.map {|n,v| [n.universal_name, v] }.sort)
    assert_equal([t, t, t], e.children)
  end

  def test_nest
    t = HTree::Text.new('t')
    b = HTree::BogusETag.new('a')
    x = HTree::Elem.new('e', HTree::XMLDecl.new('1.0'))
    d = HTree::Elem.new('e', HTree::DocType.new('html'))
    e = HTree::Elem.new('a', [t, t, t, b, x, d])
    assert_equal({}, e.attributes)
    assert_equal([t, t, t, b, x, d], e.children)
  end

  def test_err
    assert_raises(TypeError) { HTree::Elem.new('e', HTree::STag.new('a')) }
    assert_raises(TypeError) { HTree::Elem.new('e', HTree::ETag.new('a')) }
  end

  def test_context
    context = HTree::DefaultContext.subst_namespaces({'p'=>'u'})
    elem = HTree::Elem.new('p:n', {'p:a'=>'t'}, context)
    assert_equal('{u}n', elem.name)
    assert_equal('t', elem.get_attr('{u}a'))

    assert_same(context, elem.instance_variable_get(:@stag).inherited_context)
    assert_raises(ArgumentError) { HTree::Elem.new('e', context, context) }
  end

  def test_hash_in_array
    attrs = [{'a'=>'1'}, {'a'=>'2'}]
    assert_raises(TypeError) { HTree::Elem.new('e', attrs) }
    attrs.pop
    assert_raises(TypeError) { HTree::Elem.new('e', attrs) }
    attrs.pop
    assert_equal([], attrs)
    assert_equal(false, HTree::Elem.new('e', attrs).empty_element?)
  end
end
