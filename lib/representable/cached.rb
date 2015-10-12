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
        mapper.bindings(represented, options).each { |binding|
          binding.extend(Binding)
          # raise binding.parse_pipeline.extend(Pipeline::Debug).inspect if binding.typed?
        }
      end
    end

    # replace represented for each property in this representer.
    def update!(represented)
      @represented = represented
      self
    end

    module Binding
      def default_parse_fragment_functions
        Representable::Pipeline::Insert.(super, CachedPrepare.new, replace: Prepare)
      end

      def default_render_fragment_functions
        Representable::Pipeline::Insert.(super, CachedPrepare.new, replace: Prepare)
      end
    end

    class CachedPrepare < Function::Prepare
      def prepare_for(mod, object, binding)
        if representer = binding.cached_representer
          return representer.update!(object)
        end

        # puts "--------> caching representer for #{object} in #{binding.object_id}"
        binding.cached_representer = super
      end
    end
  end
end