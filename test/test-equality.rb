require 'test/unit'
require 'htree/equality'

class TestEQQ < Test::Unit::TestCase
  def assert_exact_equal(expected, actual, message=nil)
    full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
    assert_block(full_message) { expected.exact_equal? actual }
  end

  def test_tag_name_prefix
    tags = [
      HTree::STag.new('{u}n'),
      HTree::STag.new('p1{u}n'),
      HTree::STag.new('p2{u}n'),
      HTree::STag.new('p1:n', [], {'p1'=>'u'}),
      HTree::STag.new('p2:n', [], {'p2'=>'u'}),
    ]
    tags.each {|t1|
      tags.each {|t2|
        assert_equal(t1, t2)
      }
    }
  end

  def test_tag_attribute_name_prefix
    tags = [
      HTree::STag.new('n', [['{u}a', 'v']]),
      HTree::STag.new('n', [['p1{u}a', 'v']]),
      HTree::STag.new('n', [['p2{u}a', 'v']]),
      HTree::STag.new('n', [['p1:a', 'v']], {'p1'=>'u'}),
      HTree::STag.new('n', [['p2:a', 'v']], {'p2'=>'u'}),
    ]
    tags.each {|t1|
      tags.each {|t2|
        assert_equal(t1, t2)
      }
    }
  end

  def test_element
    assert_equal(HTree::Elem.new('p1{u}n'), HTree::Elem.new('p2{u}n'))
    assert_equal(HTree::Elem.new('n', {'p1{u}a'=>'v'}),
                 HTree::Elem.new('n', {'p2{u}a'=>'v'}))
    assert(!HTree::Elem.new('n', {'p1{u}a'=>'v'}).exact_equal?(HTree::Elem.new('n', {'p2{u}a'=>'v'})))
  end

end
