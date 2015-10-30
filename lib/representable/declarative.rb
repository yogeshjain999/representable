module Representable
  module Declarative
    def representable_attrs
      # @representable_attrs ||= build_config
      definitions
    end

    def representation_wrap=(name)
      heritage.record(:representation_wrap=, name)

      definitions.wrap = name
    end

    def collection(name, options={}, &block)
      property(name, options.merge(collection: true), &block)
    end

    def hash(name=nil, options={}, &block)
      return super() unless name  # allow Object.hash.

      options[:hash] = true
      property(name, options, &block)
    end

    # Allows you to nest a block of properties in a separate section while still mapping them to the outer object.
    def nested(name, options={}, &block)
      options = options.merge(
        :use_decorator => true,
        :getter        => lambda { |*| self },
        :setter        => lambda { |*| },
        :instance      => lambda { |*| self }
      ) # DISCUSS: should this be a macro just as :parse_strategy?

      property(name, options, &block)
    end


    include ::Declarative::Schema::DSL
    include ::Declarative::Schema::Feature
    include ::Declarative::Schema::Heritage

    def default_nested_class
      Module.new # FIXME: make that unnecessary in Declarative
    end


    NestedBuilder = ->(options) do
      Module.new do
        include Representable # FIXME: do we really need this?
        puts "@@@@@ #{options[:_features].inspect} for #{options[:_name]}"
        feature *options[:_features]
        include options[:base] if options[:base] # base when :inherit, or in decorator.

        module_eval &options[:_block]
      end
    end

    def nested_builder
      NestedBuilder
    end
  # private

    # def build_config
    #   Config.new
    # end
    def definitions
      @definitions ||= Config.new(Representable::Definition)
    end
  end
end