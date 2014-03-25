module Representable
  class CollectionDeserializer < Array # always is the targeted collection, already.
    def initialize(binding) # TODO: get rid of binding dependency
      # next step: use #get always.
      @binding = binding
      # should be call to #default:
      collection = []
      collection = binding.get if binding.sync?
      # collection = binding.get || [] #if binding.sync?

      super collection
    end

    def deserialize(fragment)
      # next step: get rid of collect.
      fragment.enum_for(:each_with_index).collect do |item_fragment, i|
        @deserializer = ObjectDeserializer.new(@binding, lambda { self[i] })

        @deserializer.call(item_fragment, i) # FIXME: what if obj nil?
      end
    end
  end


  class ObjectDeserializer
    # dependencies: Def#options, Def#create_object
    def initialize(binding, object)
      @binding = binding
      @object  = object
    end

    def call(fragment, *args)
      # TODO: this used to be handled in #serialize where Object added it's behaviour. treat scalars as objects to remove this switch:
      return fragment unless @binding.typed?

      # what if create_object is responsible for providing the deserialize-to object?
      # parse_strategy: sync could provide a :instance block, since :instance{nil} never worked with collections we don't break anything.
      # let's deprecate :instance{nil}, blocks have to return the object.
      # if @binding.sync?
      #   # TODO: this is also done when instance: { nil }
      #   @object = @object.call # call Binding#get or Binding#get[i]
      # else
        @object = @binding.create_object(fragment, @object, *args)
      # end

      # DISCUSS: what parts should be in this class, what in Binding?
      representable = prepare(@object)
      deserialize(representable, fragment, @binding.user_options)
      #yield @object
    end

  private
    def deserialize(object, fragment, options)
      object.send(@binding.deserialize_method, fragment, options)
    end

    def prepare(object)
      mod = @binding.representer_module_for(object)

      return object unless mod

      mod = mod.first if mod.is_a?(Array) # TODO: deprecate :extend => [..]
      mod.prepare(object)
    end
    # in deserialize, we should get the original object?
  end
end