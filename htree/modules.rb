module HTree
  class Name; include HTree end
  class Context; include HTree end

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

  module Location; include HTree end
  module Container::Loc; include HTree::Location; end
  module Leaf::Loc; include HTree::Location; end
  module Container::Trav end
  module Leaf::Trav end
  class Doc;       module Trav; include Container::Trav end; class Loc; include Trav, Container::Loc end; include Trav end
  class Elem;      module Trav; include Container::Trav end; class Loc; include Trav, Container::Loc end; include Trav end
  class Text;      module Trav; include Leaf::Trav      end; class Loc; include Trav, Leaf::Loc      end; include Trav end
  class XMLDecl;   module Trav; include Leaf::Trav      end; class Loc; include Trav, Leaf::Loc      end; include Trav end
  class DocType;   module Trav; include Leaf::Trav      end; class Loc; include Trav, Leaf::Loc      end; include Trav end
  class ProcIns;   module Trav; include Leaf::Trav      end; class Loc; include Trav, Leaf::Loc      end; include Trav end
  class Comment;   module Trav; include Leaf::Trav      end; class Loc; include Trav, Leaf::Loc      end; include Trav end
  class BogusETag; module Trav; include Leaf::Trav      end; class Loc; include Trav, Leaf::Loc      end; include Trav end

  class Error < StandardError; end
end

