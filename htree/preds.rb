require 'htree/modules'

module HTree
  module Node
    def doc?() false end
    def elem?() false end
    def text?() false end
    def xmldecl?() false end
    def doctype?() false end
    def procins?() false end
    def comment?() false end
    def bogusetag?() false end
  end

  class Doc; def doc?() true end end
  class Elem; def elem?() true end end
  class Text; def text?() true end end
  class XMLDecl; def xmldecl?() true end end
  class DocType; def doctype?() true end end
  class ProcIns; def procins?() true end end
  class Comment; def comment?() true end end
  class BogusETag; def bogusetag?() true end end

  module Location
    def doc?() @node.doc? end
    def elem?() @node.elem? end
    def text?() @node.text? end
    def xmldecl?() @node.xmldecl? end
    def doctype?() @node.doctype? end
    def procins?() @node.procins? end
    def comment?() @node.comment? end
    def bogusetag?() @node.bogusetag? end
  end
end
