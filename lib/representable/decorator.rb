require "representable"

module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    # TODO: when moving all class methods into ClassMethods, i get a segfault.
    def self.prepare(represented)
      new(represented)
    end

    def self.default_inline_class
      Representable::Decorator
    end

    # This is called from inheritable_attr when inheriting a decorator class to a subclass.
    # Explicitly subclassing the Decorator makes sure representable_attrs is a clean version.
    def self.clone
      Class.new(self) # DISCUSS: why isn't this called by Ruby?
    end

    include Representable # include after class methods so Decorator::prepare can't be overwritten by Representable::prepare.

    def initialize(represented)
      @represented = represented
    end

  private
    def self.build_inline(base, features, name, options, &block)
      Class.new(base || default_inline_class) do
        feature *features
        class_eval &block
      end
    end
  end
end
