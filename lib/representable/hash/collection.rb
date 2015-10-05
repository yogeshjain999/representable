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
      bin   = representable_mapper(format, options).bindings(represented, options).first

      # FIXME: not finished, yet!
      Collect[*bin.default_render_fragment_functions].
        (represented, {doc: doc, fragment: represented, user_options: options, binding: bin})
    end

    def update_properties_from(doc, options, format)
      bin   = representable_mapper(format, options).bindings(represented, options).first

      value = Collect[*bin.default_parse_fragment_functions].
        (doc, fragment: doc, document: doc, binding: bin)

      represented.replace(value)
    end
  end
end
