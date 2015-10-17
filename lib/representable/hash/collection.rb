module Representable::Hash
  module Collection
    include Representable::Hash

    def self.included(base)
      base.class_eval do
        include Representable::Hash
        extend ClassMethods
        representable_attrs.add(:_self, {:collection => true})
      end
    end


    module ClassMethods
      def items(options={}, &block)
        collection(:_self, options.merge(:getter => lambda { |*| self }), &block)
      end
    end


    def create_representation_with(doc, options, format)
      bin   = representable_bindings_for(format, options).first

      Collect[*bin.default_render_fragment_functions].
        (represented, {doc: doc, fragment: represented, user_options: options, binding: bin, represented: represented})
    end

    def update_properties_from(doc, options, format)
      bin   = representable_bindings_for(format, options).first

      value = Collect[*bin.default_parse_fragment_functions].
        (doc, fragment: doc, document: doc, user_options: options, binding: bin, represented: represented)

      represented.replace(value)
    end
  end
end
