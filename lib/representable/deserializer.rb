module Representable
  # Deserializer's job is deserializing the already parsed fragment into a scalar or an object.
  # This object is then returned to the Populator.
  #
  # It respects :deserialize, :prepare, :class, :instance
  #
  # Collection bindings return an array of parsed fragment items (still native format, e.g. Nokogiri node, for nested objects).
  #
  # Workflow
  #   call -> instance/class -> prepare -> deserialize -> from_json.
  class Deserializer
    def initialize(binding)
      @binding = binding
    end

    def call(fragment, object, *args) # FIXME: args is always i.
      @binding.evaluate_option(:deserialize, object, fragment) do
        demarshal(object, fragment, @binding.user_options) # object.from_hash.
      end
    end

  private
    def demarshal(object, fragment, options)
      object.send(@binding.deserialize_method, fragment, options)
    end

    module Prepare
      def prepare(object)
        @binding.evaluate_option(:prepare, object) do
          prepare!(object)
        end
      end

      def prepare!(object)
        mod = @binding.representer_module_for(object)

        return object unless mod

        prepare_for(mod, object)
      end

      def prepare_for(mod, object)
        mod.prepare(object)
      end
    end
    include Prepare

    # todo: throw error here!
    def create_object(fragment, *args)
      instance_for(fragment, *args) or class_for(fragment, *args)
    end

    def class_for(fragment, *args)
      item_class = class_from(fragment, *args) or raise DeserializeError.new(":class did not return class constant.")
      item_class.new
    end

    def class_from(fragment, *args)
      @binding.evaluate_option(:class, fragment, *args)
    end

    def instance_for(fragment, *args)
      Instance.(fragment, nil, @binding, *args).last
    end
  end
end