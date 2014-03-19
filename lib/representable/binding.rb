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
      represented_exec_for(:writer, doc) do
        write_fragment(doc, get)
      end
    end

    # Parse value from doc and update the model property.
    def uncompile_fragment(doc)
      represented_exec_for(:reader, doc) do
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
      represented_exec_for(:getter) do
        exec_context.send(getter)
      end
    end

    def set(value)
      represented_exec_for(:setter, value) do
        exec_context.send(setter, value)
      end
    end

    # the remaining methods in this class are format-independent and should be in Definition.

  private
    attr_reader :exec_context

    # Execute the block for +option_name+ on the represented object.
    # Executes passed block when there's no lambda for option.
    def represented_exec_for(option_name, *args)
      return yield unless proc = self[option_name]

      proc.evaluate(exec_context, *args<<user_options)
    end

    # All lambdas are executed on exec_context which is either represented or the decorator instance.
    def call_proc_for(proc, *args)
      raise
      return proc unless proc.is_a?(Proc)
      # TODO: call method when proc is sympbol.
      args << user_options # DISCUSS: we assume user_options is a Hash!
      exec_context.instance_exec(*args, &proc)
    end

    def evaluate_option(name, *args)
      return unless proc = self[name]

      return proc.evaluate(exec_context, *args<<user_options)
    end


    module Prepare
      def representer_module_for(object, *args)
        return unless self[:extend]
        args << user_options
        puts args.inspect
        return self[:extend].evaluate(exec_context, object, *args) # FIXME: evaluate_option
        call_proc_for(representer_module, object)   # TODO: how to pass additional data to the computing block?`
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
