module Representable
  # Using this module only makes sense with Decorator representers.
  #
  # We could further save time by caching the "mapper" (Render/Parse) on the class level: Render.new(representable_attrs).()
  module Cached
    module Property
      def property(*)
        super.tap do |property|
          # this line is ugly, but for caching, there's no need to introduce complex polymorphic code as 99% use Hash/JSON anyway.
          binding_builder = self<Representable::Hash ? Representable::Hash::Binding : Representable::XML::Binding

          # TODO: this will cause trouble with inheritance, as inherited properties don't go through the property method.
          map << binding_builder.build(property, nil)
        end
      end
    end

    def self.included(includer)
      includer.extend(Property)

      includer.class_eval do
        require "uber/inheritable_attr"
        extend Uber::InheritableAttr
        inheritable_attr :map

        self.map = Binding::Map.new
      end
    end

    def representable_map(*)
      self.class.map
    end
  end
end