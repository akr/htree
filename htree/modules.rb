module HTree
  class Name; include HTree end
  class Context; include HTree end

  class Loc; include HTree end

  # :stopdoc:
  module Tag; include HTree end
    class STag; include Tag end
    class ETag; include Tag end
  # :startdoc:

  module Node; include HTree end
    module Container; include Node end
      class Doc; include Container end
      class Elem; include Container end
    module Leaf; include Node end
      class Text; include Leaf end
      class XMLDecl; include Leaf end
      class DocType; include Leaf end
      class ProcIns; include Leaf end
      class Comment; include Leaf end
      class BogusETag; include Leaf end

  class Error < StandardError; end
end

