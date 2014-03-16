module Representable
  module Feature
    module ReadableWriteable
      def deserialize_property(binding, doc, options)
        return unless binding.writeable?
        super
      end

      def serialize_property(binding, doc, options)
        return unless binding.readable?
        super
      end
    end
  end

  # TODO: i hate monkey-patching Definition here since it globally adds this options. However, for now this should be ok :-)
  Definition.class_eval do
    # Checks and returns if the property is writeable
    def writeable?
      return self[:writeable] if self.has_key?(:writeable)
      true
    end

    # Checks and returns if the property is readable
    def readable?
      return self[:readable] if self.has_key?(:readable)
      true
    end
  end
end