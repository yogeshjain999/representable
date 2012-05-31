module Representable
  # Created at class compile time. Keeps configuration options for one property.
  class Definition
    attr_reader :name, :options
    alias_method :getter, :name
    
    def initialize(sym, options={})
      @name     = sym.to_s
      @options  = options
    end
    
    def clone
      self.class.new(name, options.clone) # DISCUSS: make generic Definition.cloned_attribute that passes list to constructor.
    end

    def setter
      :"#{name}="
    end
    
    def typed?
      sought_type.is_a?(Class) or representer_module  # also true if only :extend is set, for people who want solely rendering.
    end
    
    def array?
      options[:collection]
    end
    
    def hash?
      options[:hash]
    end
    
    def sought_type
      options[:class]
    end
    
    def from
      (options[:from] || name).to_s
    end
    
    def default_for(value)
      return default if skipable_nil_value?(value)
      value
    end
    
    def representer_module
      options[:extend]
    end
    
    def attribute
      options[:attribute]
    end
    
    def skipable_nil_value?(value)
      value.nil? and not options[:represent_nil]
    end
    
  private
    def default
      options[:default] ||= [] if array?  # FIXME: move to CollectionBinding!
      options[:default]
    end
  end
end
