module Representable
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
        self.class[ collect { |name, dfn| [name, dfn.clone] } ]
      end
    end


    def initialize
      @directives = {
        :features   => InheritableHash.new,
        :definitions => definitions = Definitions.new,
        :options    => InheritableHash.new
      }
    end
    attr_reader :directives

    def inherit!(parent)
      for directive in directives.keys
        directives[directive].inherit!(parent.directives[directive])
      end
    end


    def <<(definition)
      directives[:definitions] << definition
    end

    def [](name)
      directives[:definitions][name.to_s]
    end

    def collect(*args, &block)
      directives[:definitions].values.collect(*args, &block)
    end
    def size
      directives[:definitions].size
    end


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

    # Write representer configuration into this hash.
    def options
      @options ||= {}
    end

  private
    def infer_name_for(name)
      name.to_s.split('::').last.
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       downcase
    end
  end
end
