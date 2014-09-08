module Representable
  # Deserializer's job is deserializing the already parsed fragment into a scalar or an object.
  # This object is then returned to the Populator.
  class Deserializer
    def initialize(binding)
      @binding = binding
    end

    def call(fragment, *args) # FIXME: args is always i.
      return fragment unless @binding.typed? # customize with :extend. this is not really straight-forward.

      # what if create_object is responsible for providing the deserialize-to object?
      object = @binding.create_object(fragment, *args) # customize with :instance and :class.

      # DISCUSS: what parts should be in this class, what in Binding?
      representable = prepare(object) # customize with :prepare and :extend.

      deserialize(representable, fragment, @binding.user_options) # deactivate-able via :representable => false.
    end

  private
    def deserialize(object, fragment, options) # TODO: merge with #serialize.
      return object unless @binding.representable?

      @binding.send(:evaluate_option, :deserialize, object, fragment) do
        object.send(@binding.deserialize_method, fragment, options)
      end
    end

    def prepare(object)
      @binding.send(:evaluate_option, :prepare, object) do
        prepare!(object)
      end
    end

    def prepare!(object)
      mod = @binding.representer_module_for(object)

      return object unless mod

      mod = mod.first if mod.is_a?(Array) # TODO: deprecate :extend => [..]
      mod.prepare(object)
    end
    # in deserialize, we should get the original object?


    # Collection does exactly the same as Deserializer but for a collection.
    class Collection < self
      def call(fragment)
        collection = [] # this can be replaced, e.g. AR::Collection or whatever.

        fragment.each_with_index do |item_fragment, i|
          # add more per-item options here!
          next if @binding.send(:evaluate_option, :skip_parse, item_fragment)

          collection << deserialize!(item_fragment, i) # FIXME: what if obj nil?
        end

        collection # with parse_strategy: :sync, this is ignored.
      end

    private
      def deserialize!(*args)
        # TODO: re-use deserializer.
        Deserializer.new(@binding).call(*args)
      end
    end


    class Hash < Collection
      def call(hash)
        {}.tap do |hsh|
          hash.each { |key, fragment| hsh[key] = deserialize!(fragment) }
        end
      end
    end
  end
end