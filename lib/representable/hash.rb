require 'representable'
require 'representable/bindings/hash_bindings'
require 'json'

module Representable
  # The generic representer. Brings #to_hash and #from_hash to your object.
  # If you plan to write your own representer for a new media type, try to use this module (e.g., check how JSON reuses Hash's internal
  # architecture).
  module Hash
    def self.included(base)
      base.class_eval do
        include Representable # either in Hero or HeroRepresentation.
        extend ClassMethods # DISCUSS: do that only for classes?
      end
    end
    
    
    module ClassMethods
      def from_hash(*args, &block)
        create_represented(*args, &block).from_hash(*args)
      end
    end
    
    
    def from_hash(data, options={}, format=:hash)
      if wrap = options[:wrap] || representation_wrap
        data = data[wrap.to_s]
      end
      
      update_properties_from(data, options, format)
    end
    
    def to_hash(options={}, format=:hash)
      hash = create_representation_with({}, options, format)
      
      return hash unless wrap = options[:wrap] || representation_wrap
      
      {wrap => hash}
    end

  private

    def hash_binding_for_definition(definition)
      return Representable::Hash::CollectionBinding.new(definition)  if definition.array?
      return Representable::Hash::HashBinding.new(definition)        if definition.hash?
      Representable::Hash::PropertyBinding.new(definition)
    end
  end
end
