module HTree
  class Name; include HTree; end

  module Leaf; include HTree; end
    class Text; include Leaf; end
    module Markup; include Leaf; end
      class STag; include Markup; end
      class ETag; include Markup; end
        class BogusETag < ETag; end
      class XMLDecl; include Markup; end
      class DocType; include Markup; end
      class ProcIns; include Markup; end
      class Comment; include Markup; end
  module Container; include HTree; end
    class Doc; include Container; end
    class Elem; include Container; end

  class Error < StandardError; end
    class Name::Error < Error; end
    class STag::Error < Error; end
    class ETag::Error < Error; end
    class XMLDecl::Error < Error; end
    class DocType::Error < Error; end
    class ProcIns::Error < Error; end
    class Comment::Error < Error; end
    class Doc::Error < Error; end
    class Elem::Error < Error; end
end

