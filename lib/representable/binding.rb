module Representable
  # The Binding wraps the Definition instance for this property and provides methods to read/write fragments.

  # The flow when parsing is Binding#read_fragment -> Populator -> Deserializer.
  # Actual parsing the fragment from the document happens in Binding#read, everything after that is generic.
  #
  # Serialization: Serializer -> {frag}/[frag]/frag -> Binding#write
  class Binding
    class FragmentNotFound
    end

    def self.build(definition, *args)
      # DISCUSS: move #create_binding to this class?
      return definition.create_binding(*args) if definition[:binding]
      build_for(definition, *args)
    end

    def initialize(definition, represented, parent_decorator, user_options={})  # TODO: remove default arg for user options.
      @definition = definition

      # static options. do this once.
      @_representable = @definition.representable?
      @_skip_filters = self[:readable]==false || self[:writeable]==false || self[:if]

      setup!(represented, parent_decorator, user_options) # this can be used in #compile_fragment/#uncompile_fragment in case we wanna reuse the Binding instance.
    end

    attr_reader :user_options, :represented # TODO: make private/remove.

    def as # DISCUSS: private?
      @as ||= evaluate_option(:as)
    end

    # Retrieve value and write fragment to the doc.
    def compile_fragment(doc)
      evaluate_option(:writer, doc) do
        value = render_filter(get, doc)
        write_fragment(doc, value)
      end
    end

    # Parse value from doc and update the model property.
    def uncompile_fragment(doc)
      evaluate_option(:reader, doc) do
        read_fragment(doc)
      end
    end

    def write_fragment(doc, value)
      value = default_for(value)

      return if skipable_empty_value?(value)

      render_fragment(value, doc)
    end

    def render_fragment(value, doc)
      # DISCUSS: should we return a Skip object instead of this block trick? (same in Populator?)
      fragment = serialize(value) { return } # render fragments of hash, xml, yaml.

      write(doc, fragment)
    end

    def read_fragment(doc)
      fragment = read(doc) # scalar, Array, or Hash (abstract format) or un-deserialised fragment(s).

      populator.call(fragment, doc)
    end

    def render_filter(value, doc)
      evaluate_option(:render_filter, value, doc) { value }
    end

    def parse_filter(value, doc)
      evaluate_option(:parse_filter, value, doc) { value }
    end


    def get
      evaluate_option(:getter) do
        exec_context.send(getter)
      end
    end

    def set(value)
      evaluate_option(:setter, value) do
        exec_context.send(setter, value)
      end
    end

    # DISCUSS: do we really need that?
    #   1.38      0.104     0.021     0.000     0.083    40001   Representable::Binding#representer_module_for
    #   1.13      0.044     0.017     0.000     0.027    40001   Representable::Binding#representer_module_for (with memoize).
    def representer_module_for(object, *args)
      # TODO: cache this!
      evaluate_option(:extend, object) # TODO: pass args? do we actually have args at the time this is called (compile-time)?
    end

    # Evaluate the option (either nil, static, a block or an instance method call) or
    # executes passed block when option not defined.
    def evaluate_option(name, *args)
      unless proc = self[name]
        return yield if block_given?
        return
      end

      # TODO: it would be better if user_options was nil per default and then we just don't pass it into lambdas.
      options = self[:pass_options] ? Options.new(self, user_options, represented, parent_decorator) : user_options

      proc.evaluate(exec_context, *(args<<options)) # from Uber::Options::Value.
    end

    def [](name)
      @definition[name]
    end
    # TODO: i don't want to define all methods here, but it is faster!
    # TODO: test public interface.
    def getter
      @definition.getter
    end
    def setter
      @definition.setter
    end
    def typed?
      @definition.typed?
    end
    #   1.87      0.096     0.029     0.000     0.067    40001   Representable::Definition#representable?
    #   1.12      0.066     0.016     0.000     0.050    40001   Representable::Binding#representable? with `@_representable ||= definition.representable`  (no caching when false)!!!
    #   0.82      0.012     0.012     0.000     0.000    40001   Representable::Binding#representable?
    def representable?
      @_representable
    end
    def has_default?(*args)
      @definition.has_default?(*args)
    end
    def name
      @definition.name
    end
    def representer_module # FIXME: where do we need that?
      @definition.representer_module
    end
    # perf : 1.7-1.9
    #extend Forwardable
    #def_delegators :@definition, *%w([] getter setter typed? representable? has_default? name representer_module)
    # perf : 1.7-1.9
    # %w([] getter setter typed? representable? has_default? name representer_module).each do |name|
    #   define_method(name.to_sym) { |*args| @definition.send(name, *args) }
    # end

    #   1.55      0.031     0.022     0.000     0.009    60004   Representable::Binding#skipable_empty_value?
    #   1.51      0.030     0.022     0.000     0.008    60004   Representable::Binding#skipable_empty_value?
    # after polymorphism:
    # 1.44      0.031     0.022     0.000     0.009    60002   Representable::Binding#skipable_empty_value?
    def skipable_empty_value?(value)
      value.nil? and not self[:render_nil]
    end

    def default_for(value)
      return self[:default] if skipable_empty_value?(value)
      value
    end

      # 1.24      0.043     0.024     0.000     0.019    60009   Representable::Definition#array?
    def array?
      @definition.array?
    end

    # Note: this method is experimental.
    def update!(represented, parent_decorator, user_options)
      setup!(represented, parent_decorator, user_options)
    end

    # Does this binding contain :if, :readable or :writeable settings?
    def skip_filters?
      @_skip_filters
    end

  private
    def setup!(represented, parent_decorator, user_options)
      @represented      = represented
      @parent_decorator = parent_decorator
      @user_options     = user_options

      setup_exec_context!
    end

    #   1.80      0.066     0.027     0.000     0.039    30002   Representable::Binding#setup_exec_context!
    #   0.98      0.034     0.014     0.000     0.020    30002   Representable::Binding#setup_exec_context!
    def setup_exec_context!
      return @exec_context = @represented unless self[:exec_context]
      @exec_context = self             if self[:exec_context] == :binding
      @exec_context = parent_decorator if self[:exec_context] == :decorator
    end

    attr_reader :exec_context, :parent_decorator

    def serialize(object, &block)
      serializer.call(object, &block)
    end

    module Factories
      def serializer_class
        Serializer
      end

      def serializer
        @serializer ||= serializer_class.new(self).tap do
          # puts "creataiiiing serialijser"
        end
      end

      def populator
        populator_class.new(self)
      end

      def populator_class
        Populator
      end
    end
    include Factories


    # Options instance gets passed to lambdas when pass_options: true.
    # This is considered the new standard way and should be used everywhere for forward-compat.
    Options = Struct.new(:binding, :user_options, :represented, :decorator)


    # generics for collection bindings.
    module Collection
    private
      def populator_class
        Populator::Collection
      end

      def serializer_class
        Serializer::Collection
      end

      def skipable_empty_value?(value)
        # TODO: this can be optimized, again.
        return true if value.nil? and not self[:render_nil] # FIXME: test this without the "and"
        return true if self[:render_empty] == false and value and value.size == 0  # TODO: change in 2.0, don't render emtpy.
      end
    end

    # and the same for hashes.
    module Hash
    private
      def populator_class
        Populator::Hash
      end

      def serializer_class
        Serializer::Hash
      end
    end
  end


  class DeserializeError < RuntimeError
  end
end
