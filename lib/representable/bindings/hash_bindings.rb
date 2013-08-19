require 'representable/binding'

module Representable
  module Hash
    module ObjectBinding
      include Binding::Object

      def serialize_method
        :to_hash
      end

      def deserialize_method
        :from_hash
      end
    end


    class PropertyBinding < Representable::Binding
      def self.build_for(definition, *args)  # TODO: remove default arg.
        return CollectionBinding.new(definition, *args)  if definition.array?
        return HashBinding.new(definition, *args)        if definition.hash?
        new(definition, *args)
      end

      def initialize(*args) # FIXME. make generic.
        super
        extend ObjectBinding if typed?
      end

      def read(hash)
        return FragmentNotFound unless hash.has_key?(from) # DISCUSS: put it all in #read for performance. not really sure if i like returning that special thing.

        fragment = hash[from]
        deserialize_from(fragment)
      end

      def write(hash, value)
        hash[from] = serialize_for(value)
      end

      def serialize_for(value)
        serialize(value)
      end

      def deserialize_from(fragment)
        deserialize(fragment)
      end
    end

    class CollectionBinding < PropertyBinding
      def serialize_for(value)
        # value.enum_for(:each_with_index).collect { |obj, i| serialize(obj, i) } # DISCUSS: provide ary index/hash key for representer_module_for?
        value.collect { |item| serialize(item) }
      end

      def deserialize_from(fragment)
        # if :sync, #get original collection,
        #  ( iterate, i.from)->Collection#deserialize
        # if not: #get original (Array, LinkArray, ..)
        #  ( create obj )



        return Collection.new(self).deserialize(fragment)


        # fragment.collect { |item_fragment| deserialize(item_fragment) }

        fragment.enum_for(:each_with_index).collect { |item_fragment, i|
          deserialize(item_fragment, lambda { get[i] }) # FIXME: what if obj nil?
        }
      end

      class Collection < Array # always is the targeted collection, already.
        def initialize(binding, binding_deserialize_method_remove_me=:deserialize) # TODO: get rid of binding dependency
          # next step: use #get always.
          @binding_deserialize_method_remove_me=binding_deserialize_method_remove_me
          @binding = binding
          collection = []
          collection = binding.get if binding.options[:parse_strategy]==:sync
          super collection
        end

        def deserialize(fragment)
          # next step: get rid of collect.
          fragment.enum_for(:each_with_index).collect { |item_fragment, i|
            @binding.send(@binding_deserialize_method_remove_me, item_fragment, lambda { self[i] }) # FIXME: what if obj nil?
          }
        end
      end
    end


    class HashBinding < PropertyBinding
      def serialize_for(value)
        # requires value to respond to #each with two block parameters.
        {}.tap do |hsh|
          value.each { |key, obj| hsh[key] = serialize(obj) }
        end
      end

      def deserialize_from(fragment)
        {}.tap do |hsh|
          fragment.each { |key, item_fragment| hsh[key] = deserialize(item_fragment) }
        end
      end
    end
  end
end
