require 'test/unit'
require 'htree/parse'
require 'htree/equality'

class TestParse < Test::Unit::TestCase
  def test_empty
    assert_equal(HTree::Doc.new([]), HTree.parse("").eliminate_raw_string)
  end

  def test_xmlns_default
    t1 = HTree::Doc.new([
           HTree::Elem.new!(
             HTree::STag.new('x1', [['xmlns', 'bb']],
               {'xml'=>'http://www.w3.org/XML/1998/namespace'}),
             [HTree::Elem.new!(HTree::STag.new('x2', [],
                                {nil => 'bb', 'xml'=>'http://www.w3.org/XML/1998/namespace'}), nil)])
         ])
    t2 = HTree.parse('<x1 xmlns="bb"><x2>')
    assert_equal(t1, t2)
  end

  def test_doctype_root_element_name
    assert_equal('html',
      HTree.parse('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"><html>').children[0].root_element_name)
    assert_equal('HTML',
      HTree.parse('<?xml version="1.0"?><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"><HTML>').children[1].root_element_name)
  end
end
