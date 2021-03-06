require 'test/unit'
require 'htree/tag'
require 'htree/elem'
require 'htree/traverse'

class TestAttr < Test::Unit::TestCase
  def test_each_attribute
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::DefaultContext.subst_namespaces({'p'=>'u'}))
    t = HTree::Elem.new!(t)
    t.each_attribute {|n, v|
      assert_instance_of(HTree::Name, n)
      assert_instance_of(HTree::Text, v)
      assert_equal('{u}n', n.universal_name)
      assert_equal('a&amp;b', v.rcdata)
    }
  end

  def test_each_attr
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::DefaultContext.subst_namespaces({'p'=>'u'}))
    t = HTree::Elem.new!(t)
    t.each_attr {|n, v|
      assert_instance_of(String, n)
      assert_instance_of(String, v)
      assert_equal('{u}n', n)
      assert_equal('a&b', v)
    }
  end

  def test_fetch_attribute
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::DefaultContext.subst_namespaces({'p'=>'u'}))
    t = HTree::Elem.new!(t)
    v = t.fetch_attribute('{u}n')
    assert_instance_of(HTree::Text, v)
    assert_equal('a&amp;b', v.rcdata)
    assert_equal('y', t.fetch_attribute('x', 'y'))
    assert_raises(IndexError) { t.fetch_attribute('x') }
  end

  def test_get_attribute
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::DefaultContext.subst_namespaces({'p'=>'u'}))
    t = HTree::Elem.new!(t)
    v = t.get_attribute('{u}n')
    assert_instance_of(HTree::Text, v)
    assert_equal('a&amp;b', v.rcdata)
    assert_equal(nil, t.get_attribute('x'))
  end

  def test_get_attr
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::DefaultContext.subst_namespaces({'p'=>'u'}))
    t = HTree::Elem.new!(t)
    v = t.get_attr('{u}n')
    assert_instance_of(String, v)
    assert_equal('a&b', v)
    assert_equal(nil, t.get_attr('x'))
  end

  def test_loc_get_attr
    t = HTree::Elem.new('e', {'k'=>'v'})
    v = t.make_loc.get_attr('k')
    assert_instance_of(String, v)
    assert_equal('v', v)
    v = t.make_loc.fetch_attr('k')
    assert_instance_of(String, v)
    assert_equal('v', v)
  end

end
