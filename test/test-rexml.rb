require 'test/unit'
require 'htree/parse'
require 'htree/rexml'
begin
  require 'rexml/document'
rescue LoadError
end

class TestREXML < Test::Unit::TestCase
  def test_doc
    r = HTree.parse('<root/>').to_rexml
    assert_instance_of(REXML::Document, r)
  end

  def test_elem
    r = HTree.parse('<root a="b"/>').to_rexml
    assert_instance_of(REXML::Element, e = r.root)
    assert_equal('root', e.name)
    assert_equal('b', e.attribute('a').to_s)
  end

  def test_text
    r = HTree.parse('<root>aaa</root>').to_rexml
    assert_instance_of(REXML::Text, t = r.root.children[0])
    assert_equal('aaa', t.to_s)
  end

  def test_xmldecl
    s = '<?xml version="1.0"?>'
    r = HTree.parse(s + '<root>aaa</root>').to_rexml
    assert_instance_of(REXML::XMLDecl, x = r.children[0])
    assert_equal('1.0', x.version)
    assert_equal(nil, x.standalone)

    assert_instance_of(REXML::XMLDecl, HTree.parse(s).children[0].to_rexml)
  end

  def test_doctype
    s = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
    r = HTree.parse(s + '<html><title>xxx</title></html>').to_rexml
    assert_instance_of(REXML::DocType, d = r.children[0])
    assert_equal('html', d.name)
    assert_equal('PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"', d.external_id)

    assert_instance_of(REXML::DocType, HTree.parse(s).children[0].to_rexml)
  end

  def test_procins
    r = HTree.parse('<root><?xxx yyy?></root>').to_rexml
    assert_instance_of(REXML::Instruction, i = r.root.children[0])
    assert_equal('xxx', i.target)
    assert_equal('yyy', i.content)

    assert_instance_of(REXML::Instruction, HTree.parse('<?xxx yyy?>').children[0].to_rexml)
  end

  def test_comment
    r = HTree.parse('<root><!-- zzz --></root>').to_rexml
    assert_instance_of(REXML::Comment, c = r.root.children[0])
    assert_equal(' zzz ', c.to_s)
  end

  def test_bogusetag
    assert_equal(nil, HTree.parse('</e>').children[0].to_rexml)
  end

  def test_style
    assert_equal('<style>a&lt;b</style>', HTree.parse('<html><style>a<b</style></html>').to_rexml.to_s[/<style.*style>/])
  end
end if defined? REXML
