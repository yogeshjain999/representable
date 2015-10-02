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
  end
end