module Representable
  #
  # populator
      # skip_parse? --> return
      # deserialize
      # parse_filter
      # set
  class Populator
    def initialize(binding)
      @binding = binding
    end

    # goal of this is to have this workflow apply-able to collections AND to items per collection, or for items in hashes.
    def call(fragment, doc)
      # the rest should be applied per item (collection) or per fragment (collection and property)
      if fragment == Binding::FragmentNotFound
        return unless @binding.has_default?
        value = @binding[:default]
      else
        value = deserialize(fragment) { return } # stop here if skip_parse?
      end

      value = @binding.parse_filter(value, doc)
        # parse_filter
        # set
      @binding.set(value)
    end

  private
    def deserialize(fragment)
      return yield if @binding.send(:evaluate_option, :skip_parse, fragment)

      # use a Deserializer to transform fragment to/into object.
      deserializer_class.new(@binding).call(fragment) # CollectionDeserializer/HashDeserializer/etc.
    end

    def deserializer_class
      ObjectDeserializer
    end


    class Collection < self
    private
      def deserializer_class
        CollectionDeserializer
      end
    end

    class Hash < self
    private
      def deserializer_class
        HashDeserializer
      end
    end
  end
end