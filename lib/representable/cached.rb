module Representable
  # Using this module only makes sense with Decorator representers.
  module Cached
    # The main point here is that the decorator instance simply saves its mapper. Since the mapper
    # in turn stores the bindings, we have a straight-forward way of "caching" the bindings without
    # having to mess around on the class level: this all happens in the decorator _instance_.
    #
    # Every binding in turn stores its nested representer (if it has one), implementing a recursive caching.
    #
    # Decorator -> Mapper -> [Binding->Decorator, Binding]
    def representable_mapper(format, options)
      @mapper ||= super.tap do |mapper|
        mapper.bindings(represented, options).each { |binding| binding.extend(Binding) }
      end
    end

    # replace represented for each property in this representer.
    # DISCUSS: not sure if we need to replace self and user_options.
    def update!(represented)
      @represented = represented
    end

    # TODO: also for deserializer.
    # TODO: create Populator in Binding, too (easier to override).
    module Binding
      def serializer
        @__serializer ||= super.tap do |serializer|
          puts "extendin"
          serializer.extend(Serializer)
        end
      end
    end

    module Serializer
      def prepare_for(mod, object)
        if representer = @binding.cached_representer
          representer.update!(object)
          return representer
        end

        @binding.cached_representer = super(mod, object)
      end
    end
  end
end