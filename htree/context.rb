require 'htree/modules'

module HTree
  class Context
    DefaultNamespaces = {'xml'=>'http://www.w3.org/XML/1998/namespace'}
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
