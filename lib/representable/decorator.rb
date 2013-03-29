module Representable
  class Decorator
    include Representable

    def initialize(represented)
      @represented = represented
    end

    def representable_binding_for(attr, format, options)
      format.build(attr, @represented, options, Binding::RepresentingStrategy::Decorate.new)
    end
  end
end