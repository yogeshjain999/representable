require "representable/populator"
require "representable/deserializer"
require "representable/serializer"

module Representable
  # The Binding wraps the Definition instance for this property and provides methods to read/write fragments.
  class Binding
    class FragmentNotFound
    end

    def self.build(definition, *args)
      # DISCUSS: move #create_binding to this class?
      return definition.create_binding(*args) if definition[:binding]
      build_for(definition, *args)
    end

    def initialize(definition, represented, decorator, user_options={})  # TODO: remove default arg for user options.
      @definition   = definition
      @represented  = represented
      @decorator    = decorator
      @user_options = user_options

      setup_exec_context!
    end

    attr_reader :user_options, :represented # TODO: make private/remove.

    def as # DISCUSS: private?
      evaluate_option(:as)
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
        read_fragment(doc)# do |value|
        #   value = parse_filter(value, doc)
        #   set(value)
        # end
      end
    end

    def write_fragment(doc, value)
      value = default_for(value)

      write_fragment_for(value, doc)
    end

    def write_fragment_for(value, doc)
      return if skipable_empty_value?(value)
      write(doc, value)
    end

    def read_fragment(doc)
      fragment = read(doc)

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
    def representer_module_for(object, *args)
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
      options = self[:pass_options] ? Options.new(self, user_options, represented, decorator) : user_options

      proc.evaluate(exec_context, *(args<<options)) # from Uber::Options::Value.
    end

  private
    # Apparently, SimpleDelegator is super slow due to a regex, so we do it
    # ourselves, right, Jimmy?
    def method_missing(*args, &block)
      @definition.send(*args, &block)
    end

    def setup_exec_context!
      context = represented
      context = self        if self[:exec_context] == :binding
      context = decorator   if self[:exec_context] == :decorator

      @exec_context = context
    end

    attr_reader :exec_context, :decorator

    # Options instance gets passed to lambdas when pass_options: true.
    # This is considered the new standard way and should be used everywhere for forward-compat.
    Options = Struct.new(:binding, :user_options, :represented, :decorator)


    # Delegates to call #to_*/from_*.
    module Object
      def serialize(object)
        ObjectSerializer.new(self, object).call
      end

    private
      def populator
        populator_class.new(self)
      end

      def populator_class
        Populator
      end
    end


    # generics for collection bindings.
    module Collection
    private
      def populator_class
        Populator::Collection
      end
    end

    # and the same for hashes.
    module Hash
    private
      def populator_class
        Populator::Hash
      end
    end
  end


  class DeserializeError < RuntimeError
  end
end
