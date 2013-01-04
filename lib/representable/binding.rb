require 'delegate'

module Representable
  # The Binding wraps the Definition instance for this property and provides methods to read/write fragments.
  class Binding < SimpleDelegator
    class FragmentNotFound
    end
    
    def definition  # TODO: remove in 1.4.
      raise "Binding#definition is no longer supported as all Definition methods are now delegated automatically."
    end

    def initialize(definition, represented)
      super(definition)
      @represented = represented
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
      def serialize(*)
        extend_for(super)
      end
      
      def deserialize(*)
        extend_for(super)
      end
      
      def extend_for(object)
        if mod = representer_module_for(object) # :extend.
          object.extend(*mod)
        end

        object
      end
    
    private
      def representer_module_for(object, *args)
        call_proc_for(representer_module, object)   # TODO: how to pass additional data to the computing block?`
      end

      def call_proc_for(proc, *args)
        return proc unless proc.is_a?(Proc)
        @represented.instance_exec(*args, &proc)
      end
    end
    
    module Object
      include Binding::Extend  # provides #serialize/#deserialize with extend.
      
      def serialize(object)
        return object if object.nil?
        
        super.send(serialize_method, :wrap => false)  # TODO: pass :binding => self
      end
      
      def deserialize(data)
        # DISCUSS: does it make sense to skip deserialization of nil-values here?
        super(create_object(data)).send(deserialize_method, data)
      end
      
      def create_object(fragment)
        instance_for(fragment) or class_for(fragment)
      end

    private
      def class_for(fragment, *args)
        item_class = class_from(fragment) or return fragment # DISCUSS: is it legal to return the very fragment here?
        item_class.new
      end

      def class_from(fragment, *args)
        call_proc_for(sought_type, fragment)
      end

      def instance_for(fragment, *args)
        return unless options[:instance] 
        call_proc_for(options[:instance], fragment)
      end
    end
  end
end
