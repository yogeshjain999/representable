require 'uber/options'

module Representable
  # Created at class compile time. Keeps configuration options for one property.
  class Definition < Hash
    attr_reader :name
    alias_method :getter, :name

    def initialize(sym, options={})
      # deprecations:
      raise "The :from option got replaced by :as in Representable 1.8!" if options[:from]

      super()
      @name     = sym.to_s

      # defaults:
      options[:as] ||= @name

      setup!(options)
    end

    # TODO: test merge!.
    def merge!(options)
      setup!(options)
      self
    end

    private :default, :[]=

    def options # TODO: remove in 1.9.
      warn "Representable::Definition#option is deprecated, use #[] directly."
      self
    end

    def setter
      :"#{name}="
    end

    def typed?
      self[:class] or self[:extend] or self[:instance]
    end

    def representable?
      return if self[:representable] === false
      self[:representable] or typed?
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
      self[:extend]
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

  private
    def setup!(options)
      handle_extend!(options)
      handle_as!(options)

      # todo: aS:
      for name, value in options
        value = Uber::Options::Value.new(value) if dynamic_options.include?(name)
        self[name] = value
      end
    end

    def dynamic_options
      [:as, :getter, :setter, :class, :instance, :reader, :writer, :extend, :prepare]
    end

    def handle_extend!(options)
      mod = options.delete(:extend) || options.delete(:decorator) and options[:extend] = mod
    end

    def handle_as!(options)
      options[:as] = options[:as].to_s if options[:as].is_a?(Symbol) # Allow symbols for as:
    end
  end
end
