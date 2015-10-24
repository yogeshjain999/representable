require "uber/delegates"

module Representable
  module Declarative
    # DSL object.
    class Defaults
      def initialize
        @static_options = {}
      end

      def merge!(hash, &block)
        @static_options.merge!(hash) if hash.any?
        @dynamic_options = block if block_given?
        self
      end

      extend Uber::Delegates
      delegates :@static_options, :[], :[]= # mutuable API!

      # TODO: allow to receive rest of options/block in dynamic block. or, rather, test it as it was already implemented.
      def call(name, given_options)
        options = @static_options
        options = options.merge(dynamic_options(name, given_options))
        options = options.merge(given_options)
      end

    private
      def dynamic_options(name, given_options)
        return {} if @dynamic_options.nil?
        @dynamic_options.call(name, given_options)
      end
    end

    def representable_attrs
      @representable_attrs ||= build_config
    end

    def defaults(options={}, &block)
      heritage.record(:defaults, options, &block) # FIXME: this adds shit to defaults when called without args.

      (@defaults ||= Defaults.new).merge!(options, &block) # FIXME: what if called twice?
    end

    def representation_wrap=(name)
      heritage.record(:representation_wrap=, name)

      representable_attrs.wrap = name
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

    def property(name, options={}, &block)
      options = defaults.(name, options)

      # wenn default da is, kann man einfach default m_i mit options[m_i] mergen.

      mi = options[:include_modules] || []

      # if  && options[:include_modules].any? # TODO: when calling ::feature, don't save it, make it a options default for this representer.
      #   _opts = {}
      # else
        @features ||= {}
        _opts = {include_modules: @features.keys+mi}
      puts "@@@@@ #{name.inspect}: #{_opts.inspect}"
      # end

      # TODO: heritage does not contain include_modules (it could, be this will come via the inherited defaults)
      heritage.record(:property, name, options.merge(_opts), &block)

      representable_attrs.add(name, options) do |default_options| # handles :inherit.
        build_definition(name, default_options.merge!(_opts), &block)
      end
    end

    require "declarative"
    def heritage
      @heritage ||= ::Declarative::Heritage.new
    end

    def build_inline(base, features, name, options, &block) # DISCUSS: separate module?
      Module.new do
        include Representable
        feature *features # Representable::JSON or similar.
        include base if base # base when :inherit, or in decorator.

        module_eval &block
      end
    end

  private
    def build_definition(name, options, &block)
      base = nil

      if options[:inherit] # TODO: move this to Definition.
        base = representable_attrs.get(name).representer_module
      end # FIXME: can we handle this in super/Definition.new ?

      if block
        includes = options[:include_modules]

        options[:_inline] = true
        options[:extend]  = inline_representer_for(base, includes, name, options, &block)
      end
    end

    def inline_representer_for(base, includes, name, options, &block)
      representer = options[:use_decorator] ? Decorator : self

      representer.build_inline(base, includes, name, options, &block)
    end

    def build_config
      Config.new
    end
  end # Declarations
end