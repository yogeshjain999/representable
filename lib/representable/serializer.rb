
module Representable
  Getter = ->(options) do
    binding = options[:binding]

    binding.evaluate_option(:getter) do
      binding.send(:exec_context).send(binding.getter)
    end
  end

  Writer = ->(options) do
    options[:binding].evaluate_option(:writer, options[:doc]) do
      options[:result]
    end
  end

  StopOnSkipable = ->(options) do
    return Pipeline::Stop if options[:binding].send(:skipable_empty_value?, options[:result])
    options[:result]
  end

  RenderFilter = ->(options) do
    options[:binding].render_filter(options[:result], options[:doc]) # FIXME.
  end

  SkipRender = ->(options) do
    return Pipeline::Stop if options[:binding].evaluate_option_with_deprecation(:skip_render, options, :result, :user_options)
    options[:result]
  end

  # FIXME: Collect always assigns :fragment as input. how are we gonna handle that?
  Serialize = ->(options) do
    object, binding = options[:result], options[:binding]
    return object if object.nil?

    binding.evaluate_option(:serialize, object) do
      object.send(binding.serialize_method, binding.user_options) # FIXME: what options here?
    end
  end


  Write = ->(options) { options[:binding].write(options[:doc], options[:result]) }


  # serialize -> serialize! -> marshal. # TODO: same flow in deserialize.
  class Serializer
    def initialize(binding)
      @binding = binding
    end
    def call(object, &block)
       # DISCUSS: move to Object#serialize ?

      serialize(object, @binding.user_options, &block)
    end

  private


    class Collection < self
      def serialize(array, *args)
        collection = [] # TODO: unify with Deserializer::Collection.

        array.each do |item|
          next if @binding.evaluate_option(:skip_render, item) # TODO: allow skipping entire collections? same for deserialize.

          collection << serialize!(item, *args)
        end # TODO: i don't want Array but Forms here - what now?

        collection
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