require 'test/unit'
require 'htree/gencode'
require 'htree/parse'

class TestGenCode < Test::Unit::TestCase
  def run_code(code, context)
    out = HTree::Encoder.new(HTree::Encoder.internal_charset, HTree::Encoder.internal_charset)
    eval(code).call(out, context)
    out.finish
  end

  def test_xmlns
    t = HTree.parse_xml('<p:n xmlns:p=z><p:m>bb').root.children[0] # <p:m>bb</p:m>
    code = t.generate_xml_output_code
    
    procedure = eval(code)

    assert_equal('<p:m xmlns:p="z">bb</p:m>', run_code(code, HTree::DefaultContext))
    assert_equal('<p:m>bb</p:m>', run_code(code, HTree::DefaultContext.subst_namespaces("p"=>"z")))
  end

  def test_xmlns_chref
    t = HTree.parse_xml('<p:n xmlns:p="a&amp;<>&quot;b">').root
    code = t.generate_xml_output_code
    assert_equal('<p:n xmlns:p="a&amp;&lt;&gt;&quot;b" />', run_code(code, HTree::DefaultContext))
  end

end

