module HTree
  class Context
    DefaultNamespaces = {'xml'=>'http://www.w3.org/XML/1998/namespace'}
    DefaultNamespaces.default = ""
    DefaultNamespaces.freeze

    # The optional argument `namespaces' should be a hash or nil.
    # HTree:DefaultNamespaces is used if nil is specified.
    #
    # If it is a hash, its key should be nil or a string.
    # nil means default namespace.
    # The string means some prefix which must not be empty.
    #
    # The hash value should be a string.
    # The empty string "" means unbound namespace.
    def initialize(namespaces=nil)
      namespaces ||= DefaultNamespaces
      namespaces.each_pair {|k, v|
        check_namespace_prefix(k)
        check_namespace_uri(v)
      }
      namespaces = namespaces.dup.freeze unless namespaces.frozen?
      @namespaces = namespaces
    end

    def namespace_uri(prefix)
      @namespaces[prefix]
    end

    def subst_namespaces(declared_namespaces)
      namespaces = @namespaces.dup
      declared_namespaces.each {|k, v|
        check_namespace_prefix(k)
        check_namespace_uri(v)
        namespaces[k] = v
      }
      Context.new(namespaces)
    end

    private
    def check_namespace_prefix(k)
      unless (String === k && !k.empty?) || k == nil
        raise ArgumentError, "invalid namespace prefix: #{k.inspect}"
      end
    end

    def check_namespace_uri(v)
      unless String === v
        raise ArgumentError, "invalid namespace URI: #{v.inspect}"
      end
    end
  end

  DefaultContext = Context.new
  HTMLContext = DefaultContext.subst_namespaces(nil=>"http://www.w3.org/1999/xhtml")
end
