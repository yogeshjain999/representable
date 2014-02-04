module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    def self.prepare(represented)
      new(represented)
    end

    def self.property(name, options={}, &block)
      attr = representable_attrs[name]

      if attr && block_given? && options[:inherit] == true
        # if there is an existing representer for the given
        # attribute, create a new subclass of the representer and extend
        attr.options[:extend] = Class.new(attr.options[:extend]) do
          instance_exec(&block)
        end

        return attr
      end
      
      super
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
