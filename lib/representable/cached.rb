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

          property.merge!(cached_binding: binding=binding_builder.build(property, nil))
        end
      end
    end

    def self.included(includer)
      includer.extend(Property)
    end

    def representable_mapper(format, options)
      @mapper ||= Mapper.new(representable_attrs.collect { |dfn| dfn[:cached_binding] })
    end

    # Serializer.(doc, represented, options)
    # instance could be saved on class level.
  end
end