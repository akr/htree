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
               HTree::Context.new({'xml'=>'http://www.w3.org/XML/1998/namespace'})),
             [HTree::Elem.new!(HTree::STag.new('x2', [],
                                HTree::Context.new({nil => 'bb', 'xml'=>'http://www.w3.org/XML/1998/namespace'})), nil)])
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

  def test_procins
    t = HTree.parse("<?x?>").children[0]
    assert_equal('x', t.target)
    assert_equal(nil, t.content)
  end

  def test_eol_html
    t1 = HTree::Elem.new('a', "\nb\n")
    s = "<a>\nb\n</a>"
    t2 = HTree.parse(s).root
    assert_equal(t1, t2)
    assert_equal(s, t2.raw_string)
  end
end
