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

      root_tag = options[:wrap] || representation_wrap(options) # FIXME!
      node     = node.at_xpath(root_tag) # parse top level node from document.

      from_node(node, options)
    end

    def from_node(node, options={})
      update_properties_from(node, options, Binding)
    end

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
    def parse_xml(doc, *args)
      Oga.parse_xml(doc)
    end
  end
end

require "representable/xml/binding"
require "representable/xml/collection"
require "representable/xml/namespace"
require "representable/xml/serializer"
