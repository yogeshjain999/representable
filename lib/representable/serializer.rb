require "representable/deserializer"

module Representable
  class ObjectSerializer < ObjectDeserializer
    def initialize(binding, object)
      super(binding)
      @object = object
    end

    def call # TODO: make typed? switch here!
      return @object if @object.nil?

      representable = prepare(@object)

      serialize(representable, @binding.user_options)
    end

  private
    def serialize(object, user_options)
      return object unless @binding.representable?

      object.send(@binding.serialize_method, user_options.merge!({:wrap => false}))
    end
  end
end