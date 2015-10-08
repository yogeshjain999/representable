module Representable
  # The Binding wraps the Definition instance for this property and provides methods to read/write fragments.

  # Actually parsing the fragment from the document happens in Binding#read, everything after that is generic.
  class Binding
    class FragmentNotFound
    end

    def self.build(definition, *args)
      return definition.create_binding(*args) if definition[:binding]
      build_for(definition, *args)
    end

    def initialize(definition, parent_decorator)
      @definition       = definition
      @parent_decorator = parent_decorator # DISCUSS: where's this needed?

      # static options. do this once.
      @representable    = @definition.representable?
      @name             = @definition.name
      @skip_filters     = self[:readable]==false || self[:writeable]==false || self[:if] # Does this binding contain :if, :readable or :writeable settings?
      @getter           = @definition.getter
      @setter           = @definition.setter
      @array            = @definition.array?
      @typed            = @definition.typed?
      @has_default      = @definition.has_default?
    end

    attr_reader :user_options, :represented # TODO: make private/remove.

    attr_reader :representable, :name, :getter, :setter, :array, :typed, :skip_filters, :has_default
    alias_method :representable?, :representable
    alias_method :array?, :array
    alias_method :typed?, :typed
    alias_method :skip_filters?, :skip_filters
    alias_method :has_default?, :has_default

    def as # DISCUSS: private?
      @as ||= evaluate_option_with_deprecation(:as, nil, {}, :user_options)
    end

    # Single entry points for rendering and parsing a property are #compile_fragment
    # and #uncompile_fragment in Mapper.
    #
    # DISCUSS:
    # currently, we need to call B#update! before compile_fragment/uncompile_fragment.
    # this will change to B#renderer(represented, options).call
    #                     B#parser  (represented, options).call
    # goal is to have two objects for 2 entirely different tasks.

    # Retrieve value and write fragment to the doc.
    def compile_fragment(doc)
      options = {doc: doc, binding: self}

      render_pipeline.extend(Pipeline::Debug).(nil, options)
    end

    # Parse value from doc and update the model property.
    def uncompile_fragment(doc)
      options = {doc: doc, binding: self}

      parse_pipeline.extend(Pipeline::Debug).(doc, options)
    end

    def get # DISCUSS: evluate if we really need this.
      Getter.(nil, binding: self)
    end

    # Evaluate the option (either nil, static, a block or an instance method call) or
    # executes passed block when option not defined.
    def evaluate_option(name, *args)
      unless proc = @definition[name] # TODO: this could dispatch directly to the @definition using #send?
        return yield if block_given?
        return
      end

      options = args[0] || {} # TODO: this is time consuming, i guess.
      options[:user_options] = user_options

      proc.(exec_context, options) # from Uber::Options::Value.
    end

    def evaluate_option_with_deprecation(name, input, options, *positional_arguments)
      unless proc = @definition[name]
        return yield if block_given?
        return
      end


      options[:input] = input # DISCUSS: can we save time here?


      __options = if self[:pass_options]
        warn %{[Representable] The :pass_options option is deprecated. Please access environment objects via options[:binding].
  Learn more here: http://trailblazerb.org/gems/representable/upgrading-guide.html#pass-options}
        Options.new(self, user_options, represented, parent_decorator)
      else
        user_options
      end
      options[:user_options] = __options # TODO: always make this user_options in Representable 3.0.


      if proc.send(:proc?) or proc.send(:method?)
        arity = proc.instance_variable_get(:@value).arity if proc.send(:proc?)
        arity = exec_context.method(proc.instance_variable_get(:@value)).arity if proc.send(:method?)
        if arity  != 1 or name==:getter or name==:if or name==:as
          warn %{[Representable] Positional arguments for `:#{name}` are deprecated. Please use options or keyword arguments.
  #{name}: ->(options) { options[:#{positional_arguments.join(" | :")}] } or
  #{name}: ->(#{positional_arguments.join(":, ")}:) {  }
  Learn more here: http://trailblazerb.org/gems/representable/upgrading-guide.html#positional-arguments
  }
          deprecated_args = []
          positional_arguments.each do |arg|
            next if arg == :index && options[:index].nil?
            deprecated_args << __options  and next if arg == :user_options# either hash or Options object.
            deprecated_args << options[arg]
          end

          return proc.(exec_context, *deprecated_args)
        end
      end

      proc.(exec_context, options)
    end

    def [](name)
      @definition[name]
    end

    def skipable_empty_value?(value)
      value.nil? and not self[:render_nil]
    end

    def default_for(value)
      return self[:default] if skipable_empty_value?(value)
      value
    end

    # Note: this method is experimental.
    def update!(represented, user_options)
      @represented = represented

      setup_user_options!(user_options)
      setup_exec_context!
    end

    attr_accessor :cached_representer

    require "representable/pipeline_factories"
    include Factories

  private

    def setup_user_options!(user_options)
      @user_options  = user_options
      # this is the propagated_options.
      @user_options  = user_options.merge(wrap: false) if self[:wrap] == false
    end

    def setup_exec_context!
      return @exec_context = @represented unless self[:exec_context]
      @exec_context = self             if self[:exec_context] == :binding
      @exec_context = parent_decorator if self[:exec_context] == :decorator
    end

    attr_reader :exec_context, :parent_decorator

    def parse_pipeline
      @parse_pipeline ||= Pipeline[*evaluate_option(:parse_pipeline) { Pipeline[*parse_functions] }] # untested. # FIXME.
    end

    def render_pipeline
      @render_pipeline ||= Pipeline[*render_functions]
    end

    # Options instance gets passed to lambdas when pass_options: true.
    # This is considered the new standard way and should be used everywhere for forward-compat.
    Options = Struct.new(:binding, :user_options, :represented, :decorator)


    # generics for collection bindings.
    module Collection
      def skipable_empty_value?(value)
        # TODO: this can be optimized, again.
        return true if value.nil? and not self[:render_nil] # FIXME: test this without the "and"
        return true if self[:render_empty] == false and value and value.size == 0  # TODO: change in 2.0, don't render emtpy.
      end
    end
  end


  class DeserializeError < RuntimeError
  end
end
