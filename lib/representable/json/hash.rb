require 'representable/hash_methods'

module Representable::JSON
  module Hash
    include Representable::JSON
    include HashMethods
    
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
      end
    end
    
    
    module ClassMethods
      def values(options)
        hash :_self, options
      end
    end
    
    
    def create_representation_with(doc, options, format)
      bin   = representable_bindings_for(format).first
      hash  = filter_keys_for(self, options)
      bin.serialize_for(hash)
    end
    
    def update_properties_from(doc, options, format)
      bin   = representable_bindings_for(format).first
      value = bin.deserialize_from(doc)
      hash  = filter_keys_for(doc, options)
      replace(hash)
      self
    end
    
    # FIXME: refactor Definition so we can simply add options in #items to existing definition.
    def representable_attrs
      attrs = super
      attrs << Definition.new(:_self, :hash => true) if attrs.size == 0
      attrs
    end
  end
end
