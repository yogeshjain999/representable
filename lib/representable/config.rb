module Representable
  # Config contains three independent, inheritable directives: features, options and definitions.
  class Config
    # Keep in mind that performance doesn't matter here as 99.9% of all representers are created
    # at compile-time.

    # child.inherit(parent)
    class InheritableArray < Array
      def inherit!(parent)
        push(*parent.clone)
      end
    end

    class InheritableHash < Hash
      def inherit!(parent)
        merge!(parent.clone)
      end
    end

    # Stores Definitions from ::property. It preserves the adding order (1.9+).
    # Same-named properties get overridden, just like in a Hash.
    class Definitions < InheritableHash
      def <<(definition)
        self[definition.name] = definition
      end

      def clone
        self.class[ values.collect { |dfn| [dfn.name, dfn.clone] } ]
      end

      def [](name)
        fetch(name.to_s, nil)
      end

      def collect(*args, &block)
        values.collect(*args, &block)
      end
    end


    def initialize
      @features     = InheritableHash.new
      @definitions  = Definitions.new
      @options      = InheritableHash.new
    end
    attr_reader :features, :options, :definitions

    def inherit!(parent)
      for directive in directives
        # this should be parent.clone, not accessint the directives.
        send(directive).inherit!(parent.send(directive))
      end
    end

    # delegate #collect etc to Definitions instance.
    extend Forwardable
    def_delegators :@definitions, :[], :<<, :collect, :size


    def wrap=(value)
      value = value.to_s if value.is_a?(Symbol)
      @wrap = Uber::Options::Value.new(value)
    end

    # Computes the wrap string or returns false.
    def wrap_for(name, context, *args)
      return unless @wrap

      value = @wrap.evaluate(context, *args)

      return infer_name_for(name) if value === true
      value
    end

  private
    def directives
      %w{definitions features options}
    end

    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
end
