module Representable
  Default = ->(fragment, doc, binding,*) do
    # return Representable::Pipeline::Stop if fragment == Representable::Binding::FragmentNotFound
    if fragment == Representable::Binding::FragmentNotFound
      return Representable::Pipeline::Stop unless binding.has_default?
      return binding[:default]
    end

    fragment
  end

  SkipParse = ->(fragment, doc, binding,*) do
    return Pipeline::Stop if binding.evaluate_option(:skip_parse, fragment)
    fragment
  end

  Deserialize = ->(blaaaaaaa, doc, binding,*) do
    fragment, object = blaaaaaaa
    # use a Deserializer to transform fragment to/into object.
    binding.send(:deserializer).call(fragment, object)
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

  Set = ->(value, doc, binding,*) do
    binding.set(value)
  end


  class Iterate
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


  # Implements the pipeline that happens after the fragment has been read from the incoming document.
  class Populator
    def initialize(binding)
      @binding = binding
    end

    # goal of this is to have this workflow apply-able to collections AND to items per collection, or for items in hashes.
    def call(fragment, doc)
      Pipeline[*@binding.functions].("blaaaaaaa", fragment, doc, @binding)
    end
  end
end