require 'test/unit'
require 'htree/gencode'
require 'htree/parse'

class TestGenCode < Test::Unit::TestCase
  def test_xmlns
    t = HTree.parse('<p:n xmlns:p=z><p:m>bb').root.children[0] # <p:m>bb</p:m>
    code = t.generate_xml_output_code
    procedure = eval(code)
    assert_equal('<p:m xmlns:p="z">bb</p:m>', procedure.call(nil, "US-ASCII", HTree::DefaultContext))
    assert_equal('<p:m>bb</p:m>', procedure.call(nil, "US-ASCII", HTree::DefaultContext.subst_namespaces("p"=>"z")))
  end
end

