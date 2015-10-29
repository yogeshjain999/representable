require "representable"
require "uber/inheritable_attr"

module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    # TODO: when moving all class methods into ClassMethods, i get a segfault.
    def self.prepare(represented)
      new(represented)
    end

    def self.default_nested_class
      Representable::Decorator
    end

    # This is called from inheritable_attr when inheriting a decorator class to a subclass.
    # Explicitly subclassing the Decorator makes sure representable_attrs is a clean version.
    # FIXME: find out if we really need inheritable_attr :representer_class, etc.
    def self.clone
      Class.new(self)
    end

    include Representable # include after class methods so Decorator::prepare can't be overwritten by Representable::prepare.
    include Cached

    extend Uber::InheritableAttr
    inheritable_attr :map
    self.map = Binding::Map.new

    def initialize(represented)
      @represented = represented
    end

    NestedBuilder = ->(options) do
      base = Class.new(options[:_base]) do
        feature *options[:_features]
        class_eval(&options[:_block])
      end
    end

    def self.nested_builder
      NestedBuilder
    end
  end
end
