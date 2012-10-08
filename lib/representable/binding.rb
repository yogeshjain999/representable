require 'delegate'

module Representable
  # The Binding wraps the Definition instance for this property and provides methods to read/write fragments.
  class Binding < SimpleDelegator
    class FragmentNotFound
    end
    
    def definition  # TODO: remove in 1.4.
      raise "Binding#definition is no longer supported as all Definition methods are now delegated automatically."
    end
    
    # Main entry point for rendering/parsing a property object.
    def serialize(value)
      value
    end
    
    def deserialize(fragment)
      fragment
    end
    
    
    # Hooks into #serialize and #deserialize to extend typed properties
    # at runtime.
    module Extend
      # Extends the object with its representer before serialization.
      def serialize(object)
        extend_for(super)
      end
      
      def deserialize(*)
        extend_for(super)
      end
      
      def extend_for(object)
        if mod = representer_module
          object.extend(*mod)
        end
        
        object
      end
    end
    
    module Object
      include Binding::Extend  # provides #serialize/#deserialize with extend.
      
      def serialize(object)
        return object if object.nil?
        
        super(object).send(serialize_method, :wrap => false)
      end
      
      def deserialize(data) 
        # DISCUSS: does it make sense to skip deserialization of nil-values here?
        super(create_object).send(deserialize_method, data)
      end
      
      def create_object
        sought_type.new
      end
    end
    
  end
end
