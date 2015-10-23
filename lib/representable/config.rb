require "forwardable"

module Representable
  class Config < Hash
    # Stores Definitions from ::property. It preserves the adding order (1.9+).
    # Same-named properties get overridden, just like in a Hash.
    #
    # Overwrite definition_class if you need a custom Definition object (helpful when using
    # representable in other gems).
    class Definitions < Hash # TODO: cloneable!
      def initialize(definition_class)
        @definition_class = definition_class
        super()
      end

      def add(name, options, &block)
        if options[:inherit] and parent_property = get(name) # i like that: the :inherit shouldn't be handled outside.
          return parent_property.merge!(options, &block)
        end
        options.delete(:inherit) # TODO: can we handle the :inherit in one single place?

        self[name.to_s] = definition_class.new(name, options, &block)
      end

      def get(name)
        self[name.to_s]
      end

      def remove(name)
        delete(name.to_s)
      end

      extend Forwardable
      def_delegators :values, :each # so we look like an array. this is only used in Mapper. we could change that so we don't need to hide the hash.

    private
      attr_reader :definition_class
    end


    def initialize(definition_class=Definition)
      super()
      merge!(
        :definitions => @definitions  = Definitions.new(definition_class),
        :options     => @options      = {},
        :wrap        => nil )
    end
    attr_reader :options

    # delegate #collect etc to Definitions instance.
    extend Forwardable
    def_delegators :@definitions, :get, :add, :each, :size, :remove
    # #collect comes from Hash and then gets delegated to @definitions. don't like that.

    def wrap=(value)
      value = value.to_s if value.is_a?(Symbol)
      self[:wrap] = Uber::Options::Value.new(value)
    end

    # Computes the wrap string or returns false.
    def wrap_for(name, context, *args, &block)
      return unless self[:wrap]

      value = self[:wrap].evaluate(context, *args)

      name = yield if block_given? # DISCUSS: deprecate/restructure the entire wrapping flow.

      return infer_name_for(name) if value === true
      value
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
