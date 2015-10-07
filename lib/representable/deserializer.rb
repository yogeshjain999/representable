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


  StopOnNotFound = ->(input, options) do
    input == Binding::FragmentNotFound ? Pipeline::Stop : input
  end

  StopOnNil = ->(input, options) do # DISCUSS: Not tested/used, yet.
    input.nil? ? Pipeline::Stop : input
  end

  OverwriteOnNil = ->(input, options) do
    input.nil? ? (Setter.(input, options); Pipeline::Stop) : input
  end


  # FIXME: how to combine those two guys?
  Default = ->(input, options) do
    if input == Binding::FragmentNotFound
      return options[:binding].has_default? ?  options[:binding][:default] : Pipeline::Stop
    end
    input
  end

  # ReturnFragment = ->(options) { options[:fragment] }

  SkipParse = ->(input, options) do
    options[:binding].evaluate_option_with_deprecation(:skip_parse, input, options, :input, :user_options) ? Pipeline::Stop : input
  end

  Instance = ->(input, options) do
    options[:binding].evaluate_option_with_deprecation(:instance, input, options, :input, :index, :user_options)
  end

  module Function
    class CreateObject
      def call(input, options)
        options[:fragment] = input # FIXME: separate function?

        instance_for(input, options) || class_for(input, options)
      end

    private
      def class_for(input, options)
        item_class = class_from(input, options) or raise DeserializeError.new(":class did not return class constant for `#{options[:binding].name}`.")
        item_class.new
      end

      def class_from(input, options)
        options[:binding].evaluate_option_with_deprecation(:class, input, options, :input, :index, :user_options) # FIXME: no additional args passed here, yet.
      end

      def instance_for(input, options)
        Instance.(input, options)
      end
    end


    class Deserialize
      def call(input, options)
        options[:binding].evaluate_option_with_deprecation(:deserialize, input, options, :input, :fragment, :user_options) do
          demarshal(input, options) # object.from_hash.
        end
      end

    private
      def demarshal(input, options)
        binding = options[:binding]

        fragment, user_options = options[:fragment], binding.user_options
        input.send(binding.deserialize_method, fragment, user_options)
      end
    end


    class Prepare
      def call(input, options)
        binding = options[:binding]
        options[:result] = input

        binding.evaluate_option_with_deprecation(:prepare, input, options, :result, :user_options) do # FIXME: must be :input, right?
          prepare!(input, binding, options)
        end
      end

      def prepare!(object, binding, options)
        mod = binding.evaluate_option_with_deprecation(:extend, object, options, :input, :user_options) # FIXME: write test for extend with lambda

        return object unless mod and object # object might be nil.

        prepare_for(mod, object, binding)
      end

      def prepare_for(mod, object, binding)
        mod.prepare(object)
      end
    end
  end

  CreateObject = Function::CreateObject.new
  Deserialize  = Function::Deserialize.new
  Prepare      = Function::Prepare.new

  ParseFilter = ->(input, options) do
    options[:binding][:parse_filter].(input, options)
  end

  Setter = ->(input, options) do
    binding = options[:binding]

    binding.evaluate_option_with_deprecation(:setter, input, options, :input, :user_options) do
      binding.send(:exec_context).send(binding.setter, input)
    end
  end
end