require 'test/unit'
require 'htree/parse'
require 'htree/equality'
require 'htree/traverse'

class TestParse < Test::Unit::TestCase
  def test_empty
    assert_equal(HTree::Doc.new([]), HTree.parse_xml("").eliminate_raw_string)
  end

  def test_xmlns_default
    t1 = HTree::Doc.new([
           HTree::Elem.new!(
             HTree::STag.new('x1', [['xmlns', 'bb']],
               HTree::DefaultContext.subst_namespaces({'xml'=>'http://www.w3.org/XML/1998/namespace'})),
             [HTree::Elem.new!(HTree::STag.new('x2', [],
                                HTree::DefaultContext.subst_namespaces({nil => 'bb', 'xml'=>'http://www.w3.org/XML/1998/namespace'})), nil)])
         ])
    t2 = HTree.parse_xml('<x1 xmlns="bb"><x2>')
    assert_equal(t1, t2)
  end

  def test_doctype_root_element_name
    assert_equal('html',
      HTree.parse('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"><html>').children[0].root_element_name)

    # xxx: should be downcased?
    assert_equal('HTML',
      HTree.parse('<?xml version="1.0"?><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"><HTML>').children[1].root_element_name)
  end

  def test_doctype_system_identifier
    assert_equal('http://www.w3.org/TR/html4/loose.dtd',
      HTree.parse("<!DOCTYPE HTML SYSTEM 'http://www.w3.org/TR/html4/loose.dtd'>").children[0].system_identifier)
    assert_equal('http://www.w3.org/TR/html4/loose.dtd',
      HTree.parse("<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN' 'http://www.w3.org/TR/html4/loose.dtd'>").children[0].system_identifier)
  end

  def test_procins
    t = HTree.parse_xml("<?x?>").children[0]
    assert_equal('x', t.target)
    assert_equal(nil, t.content)
  end

  def test_eol_html
    t1 = HTree::Elem.new('a', "\nb\n")
    s = "<a>\nb\n</a>"
    t2 = HTree.parse_xml(s).root
    assert_equal(t1, t2)
    assert_equal(s, t2.raw_string)
  end

  def test_parse_html
    t1 = HTree.parse("<html>a</html>")
    assert_equal("{http://www.w3.org/1999/xhtml}html", t1.root.element_name.universal_name)
  end

  def test_bare_url
    t1 = HTree::Elem.new('a', {'href'=>'http://host/'})
    s = "<a href=http://host/>"
    t2 = HTree.parse(s).root
    assert_equal(t1, t2)
  end

  def test_bare_slash
    t1 = HTree::Elem.new('n', {'a'=>'v/'}, 'x')
    s = "<n a=v/>x"
    t2 = HTree.parse(s).root
    assert_equal(t1, t2)
  end

  def test_bare_slash_empty
    t1 = HTree::Elem.new('n', {'a'=>'v/'})
    s = "<n a=v/>"
    t2 = HTree.parse(s).root
    assert_equal(t1, t2)
  end

  def test_downcase
    assert_equal("{http://www.w3.org/1999/02/22-rdf-syntax-ns#}RDF",
      HTree.parse('<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>').root.name)
  end

  def test_downcase_name
    # HTML && !XML
    assert_equal('html', HTree.parse('<HTML>').root.element_name.local_name)
    assert_equal('html', HTree.parse('<html>').root.element_name.local_name)
    # HTML && XML
    assert_equal('html', HTree.parse('<?xml version="1.0"?><html>').root.element_name.local_name)
    assert_equal('v', HTree.parse('<?xml version="1.0"?><html X:Y=v xmlns:X=u>').root.get_attr('{u}Y'))
    # !HTML && XML
    assert_equal('RDF', HTree.parse('<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>').children[1].element_name.local_name)
  end

  def test_script_etag
    assert_equal(HTree::Doc.new(HTree::Elem.new('{http://www.w3.org/1999/xhtml}script', [])),
      HTree.parse('<script></script>'))
  end

  def test_html_emptyelem
    t = HTree.parse('<html>')
    assert_equal(HTree::Doc.new(HTree::Elem.new('{http://www.w3.org/1999/xhtml}html')), t)
    assert(!t.children[0].empty_element?)
  end

  def test_hr_emptyelem
    t = HTree.parse('<html><hr>')
    assert_equal(
      HTree::Doc.new(
        HTree::Elem.new('{http://www.w3.org/1999/xhtml}html',
          HTree::Elem.new('{http://www.w3.org/1999/xhtml}hr'))), t)
    assert(t.children[0].children[0].empty_element?)
  end

end
