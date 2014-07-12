module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    # TODO: when moving all class methods into ClassMethods, i get a segfault.
    def self.prepare(represented)
      new(represented)
    end

    # def self.default_inline_class
    #   Representable::Decorator
    # end

    include Representable # include after class methods so Decorator::prepare can't be overwritten by Representable::prepare.

    def initialize(represented)
      @represented = represented
    end

  private
    def self.build_inline(base, features, name, options, &block)
      Class.new(base || default_inline_class).tap do |decorator|
        decorator.class_eval do # Ruby 1.8.7 wouldn't properly execute the block passed to Class.new!
          include *features
          instance_exec &block
        end
      end
    end
  end
end
