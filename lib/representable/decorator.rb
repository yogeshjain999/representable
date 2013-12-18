module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    def self.prepare(represented)
      new(represented)
    end

    def self.inline_representer(base_module, name, options, &block) # DISCUSS: separate module?
      Class.new(self) do
        include base_module
        instance_exec &block
      end
    end

    include Representable # include after class methods so Decorator::prepare can't be overwritten by Representable::prepare.

    def initialize(represented)
      @represented = represented
    end
  end
end