require 'test/unit'
require 'htree/traverse'
require 'htree/parse'
require 'htree/equality'

class TestTraverse < Test::Unit::TestCase
  def test_filter
    l = HTree.parse('<a><b>x</b><b/><a/>').make_loc
    l2 = l.filter {|n| n.path != 'doc()/a/b[1]' }
    assert_equal(HTree.parse('<a><b/><a/>'), l2)
  end

  def test_title
    result = HTree::Text.new('aaa')
    t = HTree.parse('<html><title>aaa</title>')
    assert_equal(result, t.title)
    t = HTree.parse(<<'End')
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:dc="http://purl.org/dc/elements/1.1/"
         xmlns="http://purl.org/rss/1.0/">
  <channel>
    <title>aaa</title>
  </channel>
</rdf:RDF>
End
    assert_equal(result, t.title)
  end

  def test_author
    result = HTree::Text.new('xxx')
    t = HTree.parse('<html><meta name=author content=xxx>')
    assert_equal(result, t.author)
    t = HTree.parse('<html><link rev=made title=xxx>')
    assert_equal(result, t.author)
    t = HTree.parse(<<'End')
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:dc="http://purl.org/dc/elements/1.1/"
         xmlns="http://purl.org/rss/1.0/">
  <channel>
    <dc:creator>xxx</dc:creator>
  </channel>
</rdf:RDF>
End
    assert_equal(result, t.author)
    t = HTree.parse(<<'End')
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:dc="http://purl.org/dc/elements/1.1/"
         xmlns="http://purl.org/rss/1.0/">
  <channel>
    <dc:publisher>xxx</dc:publisher>
  </channel>
</rdf:RDF>
End
    assert_equal(result, t.author)
  end
end
