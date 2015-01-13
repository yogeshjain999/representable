module Representable
  module Object
    class Binding < Representable::Binding
      def self.build_for(definition, *args)  # TODO: remove default arg.
        return Collection.new(definition, *args)  if definition.array?
        new(definition, *args)
      end

      def read(hash)
        hash.send(as) # :getter? no, that's for parsing!
      end

      def deserialize_method
        :from_object
      end

      class Collection < self
        include Representable::Binding::Collection
      end
    end
  end
end