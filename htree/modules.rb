module HTree
  class Name; include HTree end
  class Context; include HTree end

  class Loc; include HTree end

  # :stopdoc:
  module Container; include HTree end
  module Leaf; include HTree end
    module Markup; include Leaf end
      class STag; include Markup end
      class ETag; include Markup end
  # :startdoc:

  module Node; include HTree end
    class Doc; include Container, Node end
    class Elem; include Container, Node end
    class Text; include Leaf, Node end
    class XMLDecl; include Markup, Node end
    class DocType; include Markup, Node end
    class ProcIns; include Markup, Node end
    class Comment; include Markup, Node end
    class BogusETag; include Markup, Node end

  class Error < StandardError; end
end

