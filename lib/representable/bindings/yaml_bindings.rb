require 'representable/binding'

module Representable
  module YAML
    module ObjectBinding
      include Binding::Object
      
      def serialize_method
        :to_ast
      end
      
      def deserialize_method
        :from_ast
      end

      def write_scalar(value)
        value
      end
    end

    class YAMLBinding < Representable::Binding
      def initialize(definition) # FIXME. make generic.
        super
        extend ObjectBinding if definition.typed?
      end
      
      def read(hash)
        return FragmentNotFound unless hash.has_key?(definition.from) # DISCUSS: put it all in #read for performance. not really sure if i like returning that special thing.
        
        fragment = hash[definition.from]
        deserialize_from(fragment)
      end
      
      def write(map, value)
        map.children << Psych::Nodes::Scalar.new(definition.from)
        map.children << serialize_for(value)  # FIXME: should be serialize.
      end
    end
    
    
    class PropertyBinding < YAMLBinding
      def serialize_for(value)
        puts "serialize: #{value.inspect}"
        write_scalar serialize(value)
      end
      
      def deserialize_from(fragment)
        deserialize(fragment)
      end

      def write_scalar(value)
        Psych::Nodes::Scalar.new(value)
      end
    end
    
    
    class CollectionBinding < PropertyBinding
      def serialize_for(value)
        Psych::Nodes::Sequence.new.tap do |seq|
          seq.style = Psych::Nodes::Sequence::FLOW if definition.options[:style] == :flow
          value.each { |obj| seq.children << super(obj) }
        end
      end
      
      def deserialize_from(fragment)
        fragment.collect { |item_fragment| deserialize(item_fragment) }
      end
    end
  end
end