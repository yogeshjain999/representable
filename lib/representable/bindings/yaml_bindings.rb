require 'representable/binding'

module Representable
  module YAML
    class PropertyBinding < Representable::Hash::PropertyBinding
      def self.build_for(definition, *args)
        return CollectionBinding.new(definition, *args) if definition.array?
        new(definition, *args)
      end

      def write(map, value)
        map.children << Psych::Nodes::Scalar.new(as)
        map.children << serialize(value)  # FIXME: should be serialize.
      end

      def serialize(value)
        write_scalar super(value)
      end

      def write_scalar(value)
        return value if typed?

        Psych::Nodes::Scalar.new(value.to_s)
      end

      def serialize_method
        :to_ast
      end

      def deserialize_method
        :from_hash
      end
    end


    class CollectionBinding < PropertyBinding
      def serialize(value)
        Psych::Nodes::Sequence.new.tap do |seq|
          seq.style = Psych::Nodes::Sequence::FLOW if options[:style] == :flow
          value.each { |obj| seq.children << super(obj) }
        end
      end

      def deserialize(fragment)  # FIXME: redundant from Hash::Bindings
        CollectionDeserializer.new(self).deserialize(fragment)
      end
    end
  end
end
