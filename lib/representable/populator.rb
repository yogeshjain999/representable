module Representable
  StopOnNotFound = -> (fragment, doc, binding, *) do
    return Pipeline::Stop if fragment == Binding::FragmentNotFound
    fragment
  end
  StopOnNil = -> (fragment, doc, binding, *) do # DISCUSS: Not tested/used, yet.
    return Pipeline::Stop if fragment.nil?
    fragment
  end
  OverwriteOnNil = -> (options) do
    if options[:fragment].nil?
      Setter.(options.merge(result: nil))
      return Pipeline::Stop
    end
    options[:fragment] # becomes :result
  end


  # FIXME: how to combine those two guys?
  Default = ->(fragment:, binding:, **opts) do
    if fragment == Binding::FragmentNotFound
      return Pipeline::Stop unless binding.has_default?
      return binding[:default]
    end
    fragment
  end

  SkipParse = ->(options) do
    puts "#{options[:binding].name} ret: #{options[:result]}"
    return Pipeline::Stop if options[:binding].evaluate_option(:skip_parse, options)
    options[:fragment]
  end


  Instance = ->(options) do
    options[:binding].evaluate_option(:instance, options)
  end

  # ->(fragment, object)=> object
  # Deserialize = ->(args, doc, binding,*) do
  Deserialize = ->(args, *) do
    # puts "Deser: #{args.inspect}"
    # fragment, object = args
    args[:binding].send(:deserializer).call(args[:fragment], args[:result]) # object.from_hash
  end
  ResolveBecauseDeserializeIsNotHereAndIShouldFixThis = -> (args, doc, binding,*) do
    fragment, object = args
    object
  end

  module Function
    class CreateObject
      def call(options)
        object = instance_for(options) || class_for(options)
        # [fragment, object]
      end

    private
      def class_for(options)
        item_class = class_from(options) or raise DeserializeError.new(":class did not return class constant.")
        item_class.new
      end

      def class_from(options)
        options[:binding].evaluate_option(:class, options) # FIXME: no additional args passed here, yet.
      end

      def instance_for(options)
        Instance.(options)
      end
    end
  end

  CreateObject = Function::CreateObject.new

  Prepare = ->(result:, binding:, **bla) do
    representer = binding.send(:deserializer).send(:prepare, result)
    # raise args.inspect
    representer
  end

  # FIXME: only add when :parse_filter!
  ParseFilter = ->(options) do
    options[:binding].parse_filter(options) # FIXME: nested pipeline!
    options[:result]
  end

  # Setter = ->(value, doc, binding,*) do
  Setter = ->(binding:, result:, **o) do
    binding.set(result)
  end


  class Collect
    def self.[](*functions)
      new(functions)
    end

    def initialize(functions)
      @item_pipeline = Pipeline[*functions]
    end

    # when stop, the element is skipped. (should that be Skip then?)
    def call(args)
      arr = [] # FIXME : THIS happens in collection deserializer.
      args[:fragment].each_with_index do |item_fragment, i|
        # DISCUSS: we should replace fragment into the existing hash
        result = @item_pipeline.(fragment: item_fragment, doc: args[:doc], binding: args[:binding], index: i)

        next if result == Pipeline::Stop
        arr << result
      end

      arr
    end


    class Hash < self
      def call(fragment:, **o)
        {}.tap do |hsh|
          fragment.each { |key, item_fragment| hsh[key] = @item_pipeline.(fragment: item_fragment, **o) }
        end
      end
    end
  end
end