module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    def self.prepare(represented)
      new(represented)
    end

    def self.inline_representer(base_module, name, options, &block)
      # FIXME: it is wrong to inherit from self here as we just want to "inherit" the included modules but nothing else.
      Class.new(self).tap do |decorator|
        decorator.class_eval do # Ruby 1.8.7 wouldn't properly execute the block passed to Class.new!
          # Remove parent's property definitions before defining the inline ones. #FIXME: don't inherit from self, remove those 2 lines.
          representable_attrs.clear
          representable_attrs.inheritable_arrays.clear

          include base_module
          instance_exec &block
        end
      end
    end

    # Allows you to nest a block of properties in a separate section while still mapping them to the outer object.
    def self.nested(name, options={}, &block)
      options = options.merge(
        :nested   => true,
        :getter   => lambda { |*| self },
        :setter   => lambda { |*| },
        :instance => lambda { |*| self }
      )

      property(name, options, &block)
    end

    include Representable # include after class methods so Decorator::prepare can't be overwritten by Representable::prepare.

    def initialize(represented)
      @represented = represented
    end
  end
end
