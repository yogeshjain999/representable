module Representable::Hash
  module Collection
    include Representable::Hash

    def self.included(base)
      base.class_eval do
        include Representable
        include Representable::Hash
        extend ClassMethods
        representable_attrs[:_self] = {:collection => true}
      end
    end


    module ClassMethods
      def items(options, &block)
        collection(:_self, options.merge(:getter => lambda { |*| self }), &block)
      end
    end


    def create_representation_with(doc, options, format)
      bin   = representable_mapper(format, options).bindings.first
      bin.write(doc, represented)
    end

    def update_properties_from(doc, options, format)
      bin   = representable_mapper(format, options).bindings.first
      value = bin.deserialize_from(doc)
      represented.replace(value)
    end
  end
end
