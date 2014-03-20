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
      self[:as]       = options.delete(:as) || @name

      setup!(options)
    end

    # TODO: test merge!.
    # TODO: make clear that this is the only writer method after #initialize.
    def merge!(options)
      setup!(options)
      self
    end

    private :default, :[]=

    def as
      self[:as]
    end

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
      r = options.delete(:extend) || options.delete(:decorator)
      options[:extend]  = r if r

      # todo: aS:
      for name, value in options
        value = Uber::Options::Value.new(value) if dynamic_options.include?(name)
        self[name] = value
      end

      self[:as] = self[:as].to_s
    end

    def dynamic_options
      [:getter, :setter, :class, :instance, :reader, :writer, :extend]
    end
  end
end
