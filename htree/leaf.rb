# htree/leaf.rb - htree leaf classes.
#
# Copyright (C) 2003,2004 Tanaka Akira  <akr@fsij.org>
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

require 'htree/modules'
require 'htree/raw_string'

module HTree
  class XMLDecl
    def initialize(version, encoding=nil, standalone=nil)
      init_raw_string
      if /\A[a-zA-Z0-9_.:-]+\z/ !~ version
        raise HTree::Error, "invalid version in XML declaration: #{version.inspect}"
      end
      if encoding && /\A[A-Za-z][A-Za-z0-9._-]*\z/ !~ encoding
        raise HTree::Error, "invalid encoding in XML declaration: #{encoding.inspect}"
      end
      unless standalone == nil || standalone == true || standalone == false
        raise HTree::Error, "invalid standalone document declaration in XML declaration: #{standalone.inspect}"
      end
      @version = version
      @encoding = encoding
      @standalone = standalone
    end
    attr_reader :version, :encoding, :standalone
  end

  class DocType
    def initialize(root_element_name, public_identifier=nil, system_identifier=nil)
      init_raw_string
      if public_identifier && /\A[ \x0d\x0aa-zA-Z0-9\-'()+,.\/:=?;!*\#@$_%]*\z/ !~ public_identifier
        raise HTree::Error, "invalid public identifier in document type declaration: #{public_identifier.inspect}"
      end
      if system_identifier && /"/ =~ system_identifier && /'/ =~ system_identifier
        raise HTree::Error, "invalid system identifier in document type declaration: #{system_identifier.inspect}"
      end

      @root_element_name = root_element_name
      @public_identifier = public_identifier
      @system_identifier = system_identifier
    end
    attr_reader :root_element_name, :public_identifier, :system_identifier
  end

  class ProcIns
    # :stopdoc:
    class << self
      alias new! new
    end
    # :startdoc:

    def ProcIns.new(target, content)
      content = content.gsub(/\?>/, '? >') if content
      new! target, content
    end

    def initialize(target, content) # :notnew:
      init_raw_string
      if content && /\?>/ =~ content
        raise HTree::Error, "invalid processing instruction content: #{content.inspect}"
      end
      @target = target
      @content = content
    end
    attr_reader :target, :content
  end

  class Comment
    # :stopdoc:
    class << self
      alias new! new
    end
    # :startdoc:

    def Comment.new(content)
      content = content.gsub(/-(-+)/) { '-' + ' -' * $1.length }.sub(/-\z/, '- ')
      new! content
    end

    def initialize(content) # :notnew:
      init_raw_string
      if /--/ =~ content || /-\z/ =~ content
        raise HTree::Error, "invalid comment content: #{content.inspect}"
      end
      @content = content
    end
    attr_reader :content
  end

  class BogusETag
    def initialize(qualified_name)
      init_raw_string
      @etag = ETag.new(qualified_name)
    end
  end
end
