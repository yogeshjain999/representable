module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    def self.prepare(represented)
      new(represented)  # was: PrepareStrategy::Decorate.
    end

    include Representable # include after class methods so Decorator::prepare can't be overwritten by Representable::prepare.

    def initialize(represented)
      @represented = represented
    end

    def representable_binding_for(attr, format, options)
      context = attr.options[:decorator_scope] ? self : represented  # DISCUSS: should Decorator know this kinda stuff?

      format.build(attr, represented, options, context)
    end
  end
end