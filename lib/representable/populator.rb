module Representable
  # we don't use keyword args, because i didn't want to discriminate 1.9 users, yet.
  # this will soon get introduces and remove constructs like options[:binding][:default].

  ReadFragment = ->(options) do
    binding, object, doc, fragment = options[:binding], options[:result], options[:doc]

    options[:fragment] =  binding.evaluate_option(:reader, doc) do
      binding.read(doc) # scalar, Array, or Hash (abstract format) or un-deserialised fragment(s).
    end
  end


  StopOnNotFound = -> (options) do
    return Pipeline::Stop if options[:fragment] == Binding::FragmentNotFound
    options[:fragment]
  end

  StopOnNil = -> (options) do # DISCUSS: Not tested/used, yet.
    return Pipeline::Stop if options[:fragment].nil?
    options[:fragment]
  end

  OverwriteOnNil = -> (options) do
    if options[:fragment].nil?
      Setter.(options.merge(result: nil))
      return Pipeline::Stop
    end
    options[:fragment] # becomes :result
  end


  # FIXME: how to combine those two guys?
  Default = ->(options) do
    if options[:fragment] == Binding::FragmentNotFound
      return options[:binding].has_default? ? options[:binding][:default] : Pipeline::Stop
    end
    options[:fragment]
  end

  ReturnFragment = ->(options) { options[:fragment] }

  SkipParse = ->(options) do
    return Pipeline::Stop if options[:binding].evaluate_option(:skip_parse, options)
    options[:fragment]
  end

  Instance = ->(options) do
    options[:binding].evaluate_option(:instance, options)
  end

  # Deserialize = ->(options) do
  #   options[:binding].send(:deserializer).call(options[:fragment], options[:result]) # object.from_hash
  # end

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
        options[:binding].evaluate_option(:class, options) # FIXME: no additional args passed here, yet.
      end

      def instance_for(options)
        Instance.(options)
      end
    end


    class Deserialize
      def call(options)
        options[:binding].evaluate_option(:deserialize, options) do
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
      def call(options)
        binding, object = options[:binding], options[:result]
        binding.evaluate_option(:prepare, object) do
          prepare!(object, binding)
        end
      end

      def prepare!(object, binding)
        mod = binding.representer_module_for(object)

        return object unless mod

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

  # FIXME: only add when :parse_filter!
  ParseFilter = ->(options) do
    options[:binding].evaluate_option(:parse_filter, options)
    options[:result]
  end

  # Setter = ->(value, doc, binding,*) do
  Setter = ->(options) do
    options[:binding].set(options[:result])
  end


  class Collect
    def self.[](*functions)
      new(functions)
    end

    def initialize(functions)
      @item_pipeline = Pipeline[*functions]#.extend(Pipeline::Debug)
    end

    # when stop, the element is skipped. (should that be Skip then?)
    def call(options)
      arr = [] # FIXME : THIS happens in collection deserializer.
      options[:fragment].each_with_index do |item_fragment, i|
        # DISCUSS: we should replace fragment into the existing hash
        result = @item_pipeline.(options.merge(fragment: item_fragment, index: i))

        next if result == Pipeline::Stop
        arr << result
      end

      arr
    end


    class Hash < self
      def call(options)
        {}.tap do |hsh|
          options[:fragment].each { |key, item_fragment| hsh[key] = @item_pipeline.(options.merge(fragment: item_fragment)) }
        end
      end
    end
  end
end