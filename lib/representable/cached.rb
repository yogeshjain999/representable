module Representable
  # Using this module only makes sense with Decorator representers.
  module Cached
    module Property
      def property(*)
        super.tap do |property|
          binding_builder = format_engine::Binding

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