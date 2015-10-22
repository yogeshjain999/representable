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

          map << binding_builder.build(property)
        end
      end
    end

    def self.included(includer)
      includer.extend(Property)
    end

    def representable_map(*)
      self.class.map
    end
  end
end