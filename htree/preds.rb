require 'htree/modules'

module HTree
  module Traverse
    def doc?() false end
    def elem?() false end
    def text?() false end
    def xmldecl?() false end
    def doctype?() false end
    def procins?() false end
    def comment?() false end
    def bogusetag?() false end
  end

  module Doc::Trav; def doc?() true end end
  module Elem::Trav; def elem?() true end end
  module Text::Trav; def text?() true end end
  module XMLDecl::Trav; def xmldecl?() true end end
  module DocType::Trav; def doctype?() true end end
  module ProcIns::Trav; def procins?() true end end
  module Comment::Trav; def comment?() true end end
  module BogusETag::Trav; def bogusetag?() true end end
end
