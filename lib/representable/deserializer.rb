module Representable
  # we don't use keyword args, because i didn't want to discriminate 1.9 users, yet.
  # this will soon get introduces and remove constructs like options[:binding][:default].

  # Deprecation strategy:
  # binding.evaluate_option_with_deprecation(:reader, options, :doc)
  #   => binding.evaluate_option(:reader, options) # always pass in options.

  AssignFragment = ->(input, options) { options[:fragment] = input }

  ReadFragment = ->(input, options) do
    binding = options[:binding]

    binding.evaluate_option_with_deprecation(:reader, input, options, :doc, :user_options) do
      binding.read(input) # scalar, Array, or Hash (abstract format) or un-deserialised fragment(s).
    end
  end


  StopOnNotFound = -> (input, options) do
    input == Binding::FragmentNotFound ? Pipeline::Stop : input
  end

  StopOnNil = -> (input, options) do # DISCUSS: Not tested/used, yet.
    input.nil? ? Pipeline::Stop : input
  end

  OverwriteOnNil = -> (input, options) do
    input.nil? ? (Setter.(input, options); Pipeline::Stop) : input
  end


  # FIXME: how to combine those two guys?
  Default = ->(options) do
    if options[:fragment] == Binding::FragmentNotFound
      return Pipeline::Stop unless options[:binding].has_default?
      options[:fragment] = options[:binding][:default]
    end
    options[:fragment]
  end

  # ReturnFragment = ->(options) { options[:fragment] }

  SkipParse = ->(options) do
    return Pipeline::Stop if options[:binding].evaluate_option_with_deprecation(:skip_parse, input, options, :fragment, :user_options)
    options[:fragment]
  end

  Instance = ->(options) do
    options[:binding].evaluate_option_with_deprecation(:instance, input, options, :fragment, :index, :user_options)
  end

  module Function
    class CreateObject
      def call(options)
        instance_for(options) || class_for(options)
      end

    private
      def class_for(options)
        item_class = class_from(options) or raise DeserializeError.new(":class did not return class constant for `#{options[:binding].name}`.")
        item_class.new
      end

      def class_from(options)
        options[:binding].evaluate_option_with_deprecation(:class, input, options, :fragment, :index, :user_options) # FIXME: no additional args passed here, yet.
      end

      def instance_for(options)
        Instance.(options)
      end
    end


    class Deserialize
      def call(options)
        options[:binding].evaluate_option_with_deprecation(:deserialize, input, options, :input, :fragment, :user_options) do
          demarshal(options) # object.from_hash.
        end
      end

    private
      def demarshal(options)
        binding = options[:binding]

        object, fragment, user_options = options[:result], options[:fragment], binding.user_options
        object.send(binding.deserialize_method, fragment, user_options)
      end
    end


    class Prepare
      def call(input, options)
        binding = options[:binding]
        options[:result] = input

        binding.evaluate_option_with_deprecation(:prepare, input, options, :result, :user_options) do
          prepare!(input, binding)
        end
      end

      def prepare!(object, binding)
        mod = binding.representer_module_for(object)

        return object unless mod and object # object might be nil.

        prepare_for(mod, object)
      end

      def prepare_for(mod, object)
        mod.prepare(object)
      end
    end
  end

  CreateObject = Function::CreateObject.new
  Deserialize  = Function::Deserialize.new
  Prepare      = Function::Prepare.new

  ParseFilter = ->(options) do
    options[:binding][:parse_filter].(options)
    # options[:result]
  end

  # Setter = ->(value, doc, binding,*) do
  Setter = ->(input, options) do
    binding = options[:binding]

    binding.evaluate_option_with_deprecation(:setter, input, options, :input, :user_options) do
      binding.send(:exec_context).send(binding.setter, input)
    end
  end
end