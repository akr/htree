module HTree
  class Name; include HTree end
  class Context; include HTree end

  class Loc; include HTree end

  # :stopdoc:
  module Container; include HTree end
  module Leaf; include HTree end
    class STag; include Leaf end
    class ETag; include Leaf end
  # :startdoc:

  module Node; include HTree end
    class Doc; include Container, Node end
    class Elem; include Container, Node end
    class Text; include Leaf, Node end
    class XMLDecl; include Leaf, Node end
    class DocType; include Leaf, Node end
    class ProcIns; include Leaf, Node end
    class Comment; include Leaf, Node end
    class BogusETag; include Leaf, Node end

  class Error < StandardError; end
end

