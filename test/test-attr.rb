require 'test/unit'
require 'htree/tag'

class TestAttr < Test::Unit::TestCase
  def test_each_attribute
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::Context.new({'p'=>'u'}))
    t.each_attribute {|n, v|
      assert_instance_of(HTree::Name, n)
      assert_instance_of(HTree::Text, v)
      assert_equal('{u}n', n.universal_name)
      assert_equal('a&amp;b', v.rcdata)
    }
  end

  def test_each_attr
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::Context.new({'p'=>'u'}))
    t.each_attr {|n, v|
      assert_instance_of(String, n)
      assert_instance_of(String, v)
      assert_equal('{u}n', n)
      assert_equal('a&b', v)
    }
  end

  def test_fetch_attribute
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::Context.new({'p'=>'u'}))
    v = t.fetch_attribute('{u}n')
    assert_instance_of(HTree::Text, v)
    assert_equal('a&amp;b', v.rcdata)
    assert_equal('y', t.fetch_attribute('x', 'y'))
    assert_raises(IndexError) { t.fetch_attribute('x') }
  end

  def test_get_attribute
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::Context.new({'p'=>'u'}))
    v = t.get_attribute('{u}n')
    assert_instance_of(HTree::Text, v)
    assert_equal('a&amp;b', v.rcdata)
    assert_equal(nil, t.get_attribute('x'))
  end

  def test_get_attr
    t = HTree::STag.new('ename', [['p:n', 'a&b']], HTree::Context.new({'p'=>'u'}))
    v = t.get_attr('{u}n')
    assert_instance_of(String, v)
    assert_equal('a&b', v)
    assert_equal(nil, t.get_attr('x'))
  end

end
