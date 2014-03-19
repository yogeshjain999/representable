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
      self[:as]       = (options.delete(:as) || @name).to_s
      #raise options[:decorator] if options[:decorator]
      r = options.delete(:extend) || options.delete(:decorator)
      self[:extend]  = r if r

      options.each { |k,v| self[k] = v }

      # todo: test
      for option in [:getter, :setter, :class, :instance, :reader, :writer, :extend
      #  :as
      ]
        self[option] = Uber::Options::Value.new(self[option]) if self.has_key?(option) # FIXME: get rid of this test.
      end
    end

    # TODO: move inherit stuff into here.
    def merge(hash)
      unwrapped = super

      for option in [:getter, :setter, :class, :instance, :reader, :writer, :extend
      #  :as
      ]
      puts unwrapped[option].inspect
        unwrapped[option] = unwrapped[option].instance_variable_get(:@value) if unwrapped[option]
    end
puts "unwrapped: #{unwrapped.inspect}"
      unwrapped
    end

    private :merge!, :default

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
      self[:class] or self[:extend] or self[:instance]  # also true if only :extend is set, for people who want solely rendering.
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
  end
end
