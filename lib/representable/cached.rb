module Representable
  # Using this module only makes sense with Decorator representers.
  module Cached
    module Property
      def property(*)
        super.tap do |property|
          # this line is ugly, but for caching, there's no need to introduce complex polymorphic code as 99% use Hash/JSON anyway.
          binding_builder = Representable::Hash::Binding
          binding_builder = Representable::XML::Binding  if self<Representable::XML
          binding_builder = Representable::YAML::Binding if self<Representable::YAML

          # TODO: this will cause trouble with inheritance, as inherited properties don't go through the property method.
          map << binding_builder.build(property)
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