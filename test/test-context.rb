require 'test/unit'
require 'htree/context'

class TestContext < Test::Unit::TestCase
  def test_namespaces_validation
    assert_raise(ArgumentError) { HTree::Context.new({1=>'u'}) }
    assert_raise(ArgumentError) { HTree::Context.new({''=>'u'}) }
    assert_raise(ArgumentError) { HTree::Context.new({'p'=>nil}) }
    assert_nothing_raised { HTree::Context.new({nil=>'u'}) }
  end

  def test_namespace_uri
    assert_equal('http://www.w3.org/XML/1998/namespace',
      HTree::Context.new.namespace_uri('xml'))
    assert_equal('u', HTree::Context.new({nil=>'u'}).namespace_uri(nil))
    assert_equal('u', HTree::Context.new({'p'=>'u'}).namespace_uri('p'))
    assert_equal(nil, HTree::Context.new({'p'=>'u'}).namespace_uri('q'))
  end

  def test_subst_namespaces
    c1 = HTree::Context.new({'p'=>'u'})
    c2 = c1.subst_namespaces({'q'=>'v'})
    assert_equal('u', c1.namespace_uri('p'))
    assert_equal(nil, c1.namespace_uri('q'))
    assert_equal('u', c2.namespace_uri('p'))
    assert_equal('v', c2.namespace_uri('q'))
  end

end
