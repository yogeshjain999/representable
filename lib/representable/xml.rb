require "representable"

begin
  require "oga"
rescue LoadError => _
  abort "Missing dependency 'oga' for Representable::XML. See dependencies section in README.md for details."
end

module Representable
  module XML
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        self.representation_wrap = true # let representable compute it.
        register_feature Representable::XML
      end
    end

    module ClassMethods
      def remove_namespaces!
        representable_attrs.options[:remove_namespaces] = true
      end

      def format_engine
        Representable::XML
      end

      def collection_representer_class
        Collection
      end
    end

    def from_xml(doc, options={})
      node = parse_xml(doc, options)



      root_tag = options[:wrap] || representation_wrap(options)
      # options = options.merge(from_node_wrap: root_tag)


      from_node_wrap = root_tag
        selector = "#{from_node_wrap}"

        _node = node.at_xpath(selector)





      from_node(_node, options)
    end

    def from_node(node, options={})


      update_properties_from(
        node,
        options,
        Binding
      )
    end

    # Returns a Nokogiri::XML object representing this object.
    def to_node(options={})
      root_tag = options[:wrap] || representation_wrap(options)

      create_representation_with(
        Node(root_tag),
        options,
        Binding
      )
    end

    def to_xml(*args)
      Render [to_node(*args)]
    end

    alias_method :render, :to_xml
    alias_method :parse, :from_xml

  private
    def remove_namespaces?
      # TODO: make local Config easily extendable so you get Config#remove_ns? etc.
      representable_attrs.options[:remove_namespaces]
    end

    def parse_xml(doc, *args)
      node = Oga.parse_xml(doc)

      # node.remove_namespaces! if remove_namespaces?
      # node
    end
  end
end

require "representable/xml/binding"
require "representable/xml/collection"
require "representable/xml/namespace"
require "representable/xml/serializer"
