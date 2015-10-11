require 'representable/binding'

module Representable
  module Hash
    class Binding < Representable::Binding
      def self.build_for(definition, *args)
        return Collection.new(definition, *args)  if definition.array?
        new(definition, *args)
      end

      def read(hash, as)
        hash.has_key?(as) ? hash[as] : FragmentNotFound
      end

      def write(hash, fragment, as)
        hash[as] = fragment
      end

      def serialize_method
        :to_hash
      end

      def deserialize_method
        :from_hash
      end

      class Collection < self
        include Representable::Binding::Collection
      end
    end
  end
end
