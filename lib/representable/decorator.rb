module Representable
  class Decorator
    include Representable

    attr_reader :represented

    def initialize(represented)
      @represented = represented
    end

    def representable_binding_for(attr, format, options)
      format.build(attr, represented, options, Binding::PrepareStrategy::Decorate.new)
    end
  end
end