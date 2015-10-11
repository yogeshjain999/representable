module Representable
  # we don't use keyword args, because i didn't want to discriminate 1.9 users, yet.
  # this will soon get introduces and remove constructs like options[:binding][:default].

  # Deprecation strategy:
  # binding.evaluate_option_with_deprecation(:reader, options, :doc)
  #   => binding.evaluate_option(:reader, options) # always pass in options.

  AssignFragment = ->(input, options) { options[:fragment] = input }

  ReadFragment = ->(input, options) do
    binding = options[:binding]

    binding.evaluate_option(:reader, input, options) do
      as = As.(input, options)
      binding.read(input, as) # scalar, Array, or Hash (abstract format) or un-deserialised fragment(s).
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

  Default = ->(input, options) do
    if input == Binding::FragmentNotFound
      return options[:binding].has_default? ?  options[:binding][:default] : Pipeline::Stop
    end
    input
  end

  SkipParse = ->(input, options) do
    options[:binding].evaluate_option(:skip_parse, input, options) ? Pipeline::Stop : input
  end

  Instance = ->(input, options) do
    options[:binding].evaluate_option(:instance, input, options)
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
        options[:binding].evaluate_option(:class, input, options) # FIXME: no additional args passed here, yet.
      end

      def instance_for(input, options)
        Instance.(input, options)
      end
    end


    class Deserialize
      def call(input, options)
        options[:binding].evaluate_option(:deserialize, input, options) do
          demarshal(input, options) # object.from_hash.
        end
      end

    private
      def demarshal(input, options)
        binding = options[:binding]

        fragment, user_options = options[:fragment], options[:user_options]
        input.send(binding.deserialize_method, fragment, user_options)
      end
    end


    class Prepare
      def call(input, options)
        binding = options[:binding]

        binding.evaluate_option(:prepare, input, options) do
          prepare!(input, binding, options)
        end
      end

      def prepare!(object, binding, options)
        mod = binding.evaluate_option(:extend, object, options) # FIXME: write test for extend with lambda

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

    binding.evaluate_option(:setter, input, options) do
      binding.send(:exec_context).send(binding.setter, input)
    end
  end


  Stop = ->(*) { Pipeline::Stop }

  If = ->(input, options) { options[:binding].evaluate_option(:if, nil, options) ? input : Pipeline::Stop }

  StopOnExcluded = ->(input, options) do
    return input unless private = options[:_private]
    return input unless props = (private[:exclude] || private[:include])

    res = props.include?(options[:binding].name.to_sym) # false with include: Stop. false with exclude: go!

    return input if private[:include]&&res
    return input if private[:exclude]&&!res
    Pipeline::Stop
  end
end