require 'htree/nodehier'

module HTree
  class Doc
    def initialize(children=[])
      @children = children.dup.freeze
    end 
    attr_reader :children

    def generate_xml(out='')
      xmldecl = false
      doctypedecl = false
      @children.each {|n|
        if n.respond_to? :generate_prolog_xmldecl_xml
          n.generate_prolog_xmldecl_xml(out) unless xmldecl
          xmldecl = true
        elsif n.respond_to? :generate_prolog_doctypedecl_xml
          n.generate_prolog_doctypedecl_xml(out) unless doctypedecl
          doctypedecl = true
        else
          n.generate_xml(out)
        end
      }
      out
    end

    def root
      es = []
      @children.each {|c| es << c if Elem === c }
      raise HTree::Error, "no element" if es.empty?
      raise HTree::Error, "multiple elements" if 1 < es.length
      es[0]
    end
  end 
end
