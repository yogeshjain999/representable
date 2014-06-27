module Representable
  # NOTE: the API of Config is subject to change so don't rely too much on this private object.
  class Config < Array
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

    class Definitions < InheritableArray
      def clone
        collect { |d| d.clone }
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
      directives[:definitions].find { |dfn| dfn.name.to_s == name.to_s }
    end

    def collect(*args, &block)
      directives[:definitions].collect(*args, &block)
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
