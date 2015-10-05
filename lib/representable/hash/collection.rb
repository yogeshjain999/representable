module Representable::Hash
  module Collection
    include Representable::Hash

    def self.included(base)
      base.class_eval do
        include Representable::Hash
        extend ClassMethods
        representable_attrs.add(:_self, {:collection => true})
      end
    end


    module ClassMethods
      def items(options={}, &block)
        collection(:_self, options.merge(:getter => lambda { |*| self }), &block)
      end
    end


    def create_representation_with(doc, options, format)
      bin   = representable_mapper(format, options).bindings(represented, options).first

      # FIXME: not finished, yet!
      # return Collect[Serialize, Write].({doc: doc, result: hash, user_options: options, binding: bin})
      if bin.typed?
        Collect[StopOnSkipable, Prepare, Serialize, WriteFragment].
          (represented, {doc: doc, fragment: represented, user_options: options, binding: bin})
      else
        Collect[StopOnSkipable, WriteFragment].
          (represented, {doc: doc, fragment: represented, user_options: options, binding: bin})
      end
    end

    def update_properties_from(doc, options, format)
      bin   = representable_mapper(format, options).bindings(represented, options).first
      # value = Deserializer::Collection.new(bin).call(doc)

      # Populator.new(bin).call()
      if bin.typed?
        value = Collect[SkipParse, CreateObject, Prepare, Deserialize].
          (doc, fragment: doc, document: doc, binding: bin)
      else
value = Collect[SkipParse].
          (doc, fragment: doc, document: doc, binding: bin)
      end


      represented.replace(value)
    end
  end
end
