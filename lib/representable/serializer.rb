require "representable/deserializer"

module Representable
  class ObjectSerializer < ObjectDeserializer
    def call
      return @object if @object.nil?

      representable = prepare(@object)

      serialize(representable, @binding.user_options)
    end

  private
    def serialize(object, user_options)
      object.send(@binding.serialize_method, user_options.merge!({:wrap => false}))
    end
  end
end