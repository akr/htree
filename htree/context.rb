require 'htree/modules'

module HTree
  class Context
    DefaultNamespaces = {'xml'=>'http://www.w3.org/XML/1998/namespace'}

    # The optional argument namespaces should be nil or a hash.
    # HTree:DefaultNamespaces is used for nil.
    #
    # If it is a hash, its key should be nil or a string.
    # nil means default namespace.
    # The string means some prefix which must not be empty.
    #
    # The hash value should be a string.
    # It may be empty which means deleted namespace.
    def initialize(namespaces=nil)
      namespaces ||= DefaultNamespaces
      namespaces.each_pair {|k, v|
        unless (String === k && !k.empty?) || k == nil
          raise ArgumentError, "invalid namespace prefix: #{k.inspect}"
        end
        unless String === v
          raise ArgumentError, "invalid namespace URI: #{v.inspect}"
        end
      }
      @namespaces = namespaces
    end

    def namespace_uri(prefix)
      @namespaces[prefix]
    end

    def subst_namespaces(declared_namespaces)
      namespaces = @namespaces.dup
      declared_namespaces.each {|k, v|
        if v == nil
          namespaces.delete k
        else
          namespaces[k] = v
        end
      }
      Context.new(namespaces)
    end
  end

  DefaultContext = Context.new
end
