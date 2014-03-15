module Representable
  # Created at class compile time. Keeps configuration options for one property.
  class Definition < Hash
    attr_reader :name, :options
    alias_method :getter, :name

    def initialize(sym, options={})
      @name     = sym.to_s

      # deprecations:
      raise "The :from option got replaced by :as in Representable 1.8!" if options[:from]

      super()

      self[:as]  = (options.delete(:as) || @name).to_s

      options.each { |k,v| self[k] = v }
    end

    private :merge!, :default

    def clone
      self.class.new(name, super) # DISCUSS: make generic Definition.cloned_attribute that passes list to constructor.
    end

    def as
      self[:as]
    end

    def options
      # TODO: deprecate.
      self
    end

    def setter
      :"#{name}="
    end

    def typed?
      deserialize_class.is_a?(Class) or representer_module or self[:instance]  # also true if only :extend is set, for people who want solely rendering.
    end

    def array?
      self[:collection]
    end

    def hash?
      self[:hash]
    end

    def deserialize_class
      self[:class]
    end

    def default_for(value)
      return self[:default] if skipable_nil_value?(value)
      value
    end

    def has_default?
      has_key?(:default)
    end

    def representer_module
      self[:extend] or self[:decorator]
    end

    def skipable_nil_value?(value)
      value.nil? and not self[:render_nil]
    end

    def create_binding(*args)
      self[:binding].call(self, *args)
    end

    def sync?
      self[:parse_strategy] == :sync
    end
  end
end
