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

          serializer << binding_builder.build(property, nil)
          deserializer << binding_builder.build(property, nil)
        end
      end
    end

    def self.included(includer)
      includer.extend(Property)

      includer.class_eval do
        require "uber/inheritable_attr"
        extend Uber::InheritableAttr
        inheritable_attr :serializer
        inheritable_attr :deserializer

        self.serializer = Render.new
        self.deserializer = Parse.new
      end
    end

    def serializer(*)
      self.class.serializer
    end

    def deserializer(*)
      self.class.deserializer
    end
  end
end