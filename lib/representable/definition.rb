require 'uber/options'
require "representable/parse_strategies"

module Representable
  # Created at class compile time. Keeps configuration options for one property.
  class Definition
    include Representable::Cloneable

    attr_reader :name
    alias_method :getter, :name

    def initialize(sym, options={})
      # @options = Inheritable::Hash.new # allows deep cloning.
      @runtime_options = {}

      @name    = sym.to_s
      options  = options.clone

      # defaults:
      options[:parse_filter]  = Pipeline[*options[:parse_filter]]
      options[:render_filter] = Pipeline[*options[:render_filter]]
      options[:as]          ||= @name

      setup!(options)

      yield options if block_given? # this allows callers of Definition#new access default options in a convenient way.
      @options = options

      runtime_options!(options)
    end

    def merge!(options, &block)
      options = options.clone

      # TODO: test that clone works.
      options[:parse_filter]  = @options[:parse_filter].push(*options[:parse_filter])
      options[:render_filter] = @options[:render_filter].push(*options[:render_filter])

      setup!(options) # FIXME: this doesn't yield :as etc.

      yield options if block_given?
      @options = options

      runtime_options!(options)
      self
    end

    extend Forwardable
    def_delegators :@runtime_options, :[], :each, :has_key?

    def clone
      self.class.new(name, @options)
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

    def default_for(value)
      return self[:default] if skipable_empty_value?(value)
      value
    end

    def has_default?
      has_key?(:default)
    end

    def representer_module
      @options[:extend]
    end

    def skipable_empty_value?(value)
      return true if array? and self[:render_empty] == false and value and value.size == 0  # TODO: change in 2.0, don't render emtpy.
      value.nil? and not self[:render_nil]
    end

    def create_binding(*args)
      self[:binding].call(self, *args)
    end

  private
    def setup!(options)
      handle_extend!(options)
      handle_as!(options)

      # DISCUSS: we could call more macros here (e.g. for :nested).
      Representable::ParseStrategy.apply!(options)
    end

    def runtime_options!(options)
      for name, value in options
        value = Uber::Options::Value.new(value) if dynamic_options.include?(name)
        @runtime_options[name] = value
      end
    end

    def dynamic_options
      [:as, :getter, :setter, :class, :instance, :reader, :writer, :extend, :prepare, :if, :deserialize, :serialize, :render_filter, :parse_filter]
    end

    def handle_extend!(options)
      mod = options.delete(:extend) || options.delete(:decorator) and options[:extend] = mod
    end

    def handle_as!(options)
      options[:as] = options[:as].to_s if options[:as].is_a?(Symbol) # Allow symbols for as:
    end
  end
end
