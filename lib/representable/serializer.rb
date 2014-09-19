require "representable/deserializer"

module Representable
  class Serializer < Deserializer
    def call(object)
      return object if object.nil? # DISCUSS: move to Object#serialize ?

      serialize(object, @binding.user_options)
    end

  private
    # Serialize one object by calling to_json etc. on it.
    def serialize(object, user_options)
      object = prepare(object)

      return object unless @binding.representable?

      @binding.evaluate_option(:serialize, object) do
        object.send(@binding.serialize_method, user_options.merge!({:wrap => false}))
      end
    end


    class Collection < self
      def serialize(array, *args)
        array.collect { |item| super(item, *args) } # TODO: i don't want Array but Forms here - what now?
      end
    end


    class Hash < self
      def serialize(hash, *args)
        {}.tap do |hsh|
          hash.each { |key, obj| hsh[key] = super(obj, *args) }
        end
      end
    end
  end
end