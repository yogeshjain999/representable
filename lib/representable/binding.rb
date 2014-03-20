require "delegate"
require "representable/deserializer"
require "representable/serializer"

module Representable
  # The Binding wraps the Definition instance for this property and provides methods to read/write fragments.
  class Binding < SimpleDelegator
    class FragmentNotFound
    end

    def self.build(definition, *args)
      # DISCUSS: move #create_binding to this class?
      return definition.create_binding(*args) if definition[:binding]
      build_for(definition, *args)
    end

    def initialize(definition, represented, user_options={}, exec_context=represented)  # TODO: remove default arg for user options. # DISCUSS: make exec_context an options hash?
      super(definition)
      @represented  = represented
      @user_options = user_options
      @exec_context = exec_context
    end

    attr_reader :user_options, :represented # TODO: make private/remove.

    # Retrieve value and write fragment to the doc.
    def compile_fragment(doc)
      evaluate_option(:writer, doc) do
        write_fragment(doc, get)
      end
    end

    # Parse value from doc and update the model property.
    def uncompile_fragment(doc)
      evaluate_option(:reader, doc) do
        read_fragment(doc) do |value|
          set(value)
        end
      end
    end

    def write_fragment(doc, value)
      value = default_for(value)

      write_fragment_for(value, doc)
    end

    def write_fragment_for(value, doc)
      return if skipable_nil_value?(value)
      write(doc, value)
    end

    def read_fragment(doc)
      value = read_fragment_for(doc)

      if value == FragmentNotFound
        return unless has_default?
        value = self[:default]
      end

      yield value
    end

    def read_fragment_for(doc)
      read(doc)
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

  private
    attr_reader :exec_context

    # Evaluate the option (either nil, static, a block or an instance method call) or
    # executes passed block when option not defined.
    def evaluate_option(name, *args)
      unless proc = self[name]
        return yield if block_given?
        return
      end

      proc.evaluate(exec_context, *args<<user_options)
    end


    module Prepare
      def representer_module_for(object, *args)
        evaluate_option(:extend, object) # TODO: pass args? do we actually have args at the time this is called (compile-time)?
      end
    end
    include Prepare


    # Delegates to call #to_*/from_*.
    module Object
      def serialize(object)
        ObjectSerializer.new(self, object).call
      end

      def deserialize(data, object=lambda { get })
        # DISCUSS: does it make sense to skip deserialization of nil-values here?
        ObjectDeserializer.new(self, object).call(data)
      end

      def create_object(fragment)
        instance_for(fragment) or class_for(fragment)
      end

    private
      def class_for(fragment, *args)
        item_class = class_from(fragment) or return fragment
        item_class.new
      end

      def class_from(fragment, *args)
        self[:class].evaluate(exec_context, fragment) # TODO: hand in all arguments!
      end

      def instance_for(fragment, *args)
        return unless self[:instance]
        self[:instance].evaluate(exec_context, fragment) or get # TODO: hand in all arguments! # DISCUSS: what is this #get call here?
      end
    end
  end
end
