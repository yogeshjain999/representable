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
      @getter           = @definition.getter
      @setter           = @definition.setter
      @array            = @definition.array?
      @typed            = @definition.typed?
      @has_default      = @definition.has_default?
    end

    attr_reader :represented # TODO: make private/remove.

    attr_reader :representable, :name, :getter, :setter, :array, :typed, :skip_filters, :has_default
    alias_method :representable?, :representable
    alias_method :array?, :array
    alias_method :typed?, :typed
    alias_method :has_default?, :has_default

    # Single entry points for rendering and parsing a property are #compile_fragment
    # and #uncompile_fragment in Mapper.
    #
    # DISCUSS:
    # currently, we need to call B#update! before compile_fragment/uncompile_fragment.
    # this will change to B#renderer(represented, options).call
    #                     B#parser  (represented, options).call
    # goal is to have two objects for 2 entirely different tasks.

    # Retrieve value and write fragment to the doc.
    def compile_fragment(options)
      render_pipeline(nil, options).(nil, options)
    end

    # Parse value from doc and update the model property.
    def uncompile_fragment(options)
      parse_pipeline(options[:doc], options).(options[:doc], options)
    end

    def get # DISCUSS: evluate if we really need this.
      warn "[Representable] Binding#get is deprecated."
      Getter.(nil, binding: self)
    end

    module EvaluateOption
      # Evaluate the option (either nil, static, a block or an instance method call) or
      # executes passed block when option not defined.
      def evaluate_option(name, input=nil, options={}) # TODO: remove this, we don't need a decider anymore.
        unless proc = @definition[name]
          return yield if block_given?
          return
        end

        proc.(exec_context, options) # from Uber::Options::Value. # NOTE: this can also be the Proc object if it's not wrapped by Uber:::Value.
      end
    end
    include EvaluateOption # make it overridable for Deprecation. will be removed in 3.0.

    require "representable/deprecations"
    include Deprecation

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
    def update!(represented)
      @represented = represented
      setup_exec_context!
    end

    attr_accessor :cached_representer

    require "representable/pipeline_factories"
    include Factories

  private

    def setup_exec_context!
      return @exec_context = @represented unless self[:exec_context]
      @exec_context = self             if self[:exec_context] == :binding
      @exec_context = parent_decorator if self[:exec_context] == :decorator
    end

    attr_reader :exec_context, :parent_decorator

    def parse_pipeline(input, options)
      @parse_pipeline ||= pipeline_for(:parse_pipeline, input, options) { Pipeline[*parse_functions] }
    end

    def render_pipeline(input, options)
      @render_pipeline ||= pipeline_for(:render_pipeline, input, options) { Pipeline[*render_functions] }
    end

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
