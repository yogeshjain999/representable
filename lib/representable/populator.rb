module Representable
  StopOnNotFound = -> (fragment, doc, binding, *) do
    return Pipeline::Stop if fragment == Binding::FragmentNotFound
    fragment
  end
  StopOnNil = -> (fragment, doc, binding, *) do # DISCUSS: Not tested/used, yet.
    return Pipeline::Stop if fragment.nil?
    fragment
  end
  OverwriteOnNil = -> (fragment, doc, binding, *) do
    if fragment.nil?
      Setter.(fragment, doc, binding)
      return Pipeline::Stop
    end
    fragment
  end


  # FIXME: how to combine those two guys?
  Default = ->(fragment, doc, binding,*) do
    if fragment == Binding::FragmentNotFound
      return Pipeline::Stop unless binding.has_default?
      return binding[:default]
    end

    fragment
  end

  SkipParse = ->(fragment, doc, binding,*) do
    return Pipeline::Stop if binding.evaluate_option(:skip_parse, fragment)
    fragment
  end


  # ->(fragment)=> [fragment, object]
  Instance = ->(fragment, doc, binding,*args) do
    [fragment, binding.evaluate_option(:instance, fragment, *args)]
  end

  # ->(fragment, object)=> object
  Deserialize = ->(args, doc, binding,*) do
    fragment, object = args
    # use a Deserializer to transform fragment to/into object.
    binding.send(:deserializer).call(fragment, object)
  end
  ResolveBecauseDeserializeIsNotHereAndIShouldFixThis = -> (args, doc, binding,*) do
    fragment, object = args
    object
  end

  CreateObject = ->(fragment, doc, binding,*args) do
    object = binding.send(:deserializer).send(:create_object, fragment, *args) # FIXME: stop that shit of passing index as a separate argument and put it in Options.

    [fragment, object]
  end

  Prepare = ->(args, doc, binding,*) do
    fragment, object = args

    representer = binding.send(:deserializer).send(:prepare, object)
    # raise args.inspect
    [fragment, representer]
  end

  ParseFilter = ->(value, doc, binding,*) do
    binding.parse_filter(value, doc) # FIXME: nested pipeline!
  end

  Setter = ->(value, doc, binding,*) do
    binding.set(value)
  end


  class Collect
    def self.[](*functions)
      new(functions)
    end

    def initialize(functions)
      @item_pipeline = Pipeline[*functions]
    end

    def call(fragment, doc, binding)
      arr = [] # FIXME : THIS happens in collection deserializer.
      fragment.each_with_index do |item_fragment, i|
        arr << @item_pipeline.(nil, item_fragment, doc, binding, i)
      end

      arr
    end


    class Hash < self
      def call(fragment, doc, binding)
        {}.tap do |hsh|
          fragment.each { |key, item_fragment| hsh[key] = @item_pipeline.(nil, item_fragment, doc, binding) }
        end
      end
    end
  end
end