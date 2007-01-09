# htree/modules.rb - htree class/module declaration.
#
# Copyright (C) 2004 Tanaka Akira  <akr@fsij.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

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

  module Traverse end
  module Container::Trav; include Traverse end
  module Leaf::Trav; include Traverse end
  class Doc;       module Trav; include Container::Trav end; include Trav end
  class Elem;      module Trav; include Container::Trav end; include Trav end
  class Text;      module Trav; include Leaf::Trav      end; include Trav end
  class XMLDecl;   module Trav; include Leaf::Trav      end; include Trav end
  class DocType;   module Trav; include Leaf::Trav      end; include Trav end
  class ProcIns;   module Trav; include Leaf::Trav      end; include Trav end
  class Comment;   module Trav; include Leaf::Trav      end; include Trav end
  class BogusETag; module Trav; include Leaf::Trav      end; include Trav end

  class Location; include HTree end
  module Container::Loc end
  module Leaf::Loc end
  class Doc;       class Loc < Location; include Trav, Container::Loc end end
  class Elem;      class Loc < Location; include Trav, Container::Loc end end
  class Text;      class Loc < Location; include Trav, Leaf::Loc      end end
  class XMLDecl;   class Loc < Location; include Trav, Leaf::Loc      end end
  class DocType;   class Loc < Location; include Trav, Leaf::Loc      end end
  class ProcIns;   class Loc < Location; include Trav, Leaf::Loc      end end
  class Comment;   class Loc < Location; include Trav, Leaf::Loc      end end
  class BogusETag; class Loc < Location; include Trav, Leaf::Loc      end end

  class Error < StandardError; end
end

