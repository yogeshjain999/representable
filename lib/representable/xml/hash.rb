require 'representable/hash_methods'

module Representable::XML
  module AttributeHash
    include Representable::XML
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
      #bin   = representable_bindings_for(format).first
      bin   = AttributeHashBinding.new(Representable::Definition.new(:_self))
      hash  = filter_keys_for(self, options)
      bin.write(doc, hash)
    end
    
    def update_properties_from(doc, options, format)
      #bin   = representable_bindings_for(format).first
      bin   = AttributeHashBinding.new(Representable::Definition.new(:_self))
      hash  = filter_keys_for(doc, options)
      value = bin.deserialize_from(hash)
      replace(value)
      self
    end
    
    # FIXME: refactor Definition so we can simply add options in #items to existing definition.
    def representable_attrs
      attrs = super
      attrs << Definition.new(:_self, :hash => true) if attrs.size == 0
      attrs
    end
  end
  
  module Hash
    include Representable::XML
    
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
      bin.serialize_for(self)
    end
    
    def update_properties_from(doc, options, format)
      bin   = representable_bindings_for(format).first
      value = bin.deserialize_from(doc)
      replace(value)
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
