module HTree
  class Leaf; include HTree; end
    class Text < Leaf; end
    class Markup < Leaf; end
      class STag < Markup; end
      class ETag < Markup; end
        class BogusETag < ETag; end
      class XMLDecl < Markup; end
      class DocType < Markup; end
      class ProcIns < Markup; end
      class Comment < Markup; end
  class Container; include HTree; end
    class Doc < Container; end
    class Elem < Container; end


  class Error < StandardError; end
  class STag::Error < Error; end
  class ETag::Error < Error; end
  class XMLDecl::Error < Error; end
  class DocType::Error < Error; end
  class ProcIns::Error < Error; end
  class Comment::Error < Error; end
end

