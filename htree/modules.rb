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

  module Loc; include HTree end
  class Doc;       module Traverse end; class Location; include Loc, Traverse end; include Traverse end
  class Elem;      module Traverse end; class Location; include Loc, Traverse end; include Traverse end
  class Text;      module Traverse end; class Location; include Loc, Traverse end; include Traverse end
  class XMLDecl;   module Traverse end; class Location; include Loc, Traverse end; include Traverse end
  class DocType;   module Traverse end; class Location; include Loc, Traverse end; include Traverse end
  class ProcIns;   module Traverse end; class Location; include Loc, Traverse end; include Traverse end
  class Comment;   module Traverse end; class Location; include Loc, Traverse end; include Traverse end
  class BogusETag; module Traverse end; class Location; include Loc, Traverse end; include Traverse end

  class Error < StandardError; end
end

