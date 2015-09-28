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



require "representable/pipeline"
  typed = Pipeline[SkipParse, CreateObject, Prepare, Deserialize]
  Iterate = ->(fragment, doc, binding) do
          arr = [] # FIXME : THIS happens in collection deserializer.
          fragment.each_with_index do |item_fragment, i|
            arr << typed.("blaaaa", item_fragment, doc, binding, i) # FIXME: need to pass in index (Options!!!)
          end

          arr
        end

  ScalarIterate = ->(fragment, doc, binding) do
          arr = [] # FIXME : THIS happens in collection deserializer.
          fragment.each_with_index do |item_fragment, i|
            arr << Pipeline[SkipParse].("blaaaa", item_fragment, doc, binding)
          end

          arr
        end


  class Populator
    def initialize(binding)
      @binding = binding
    end

    # goal of this is to have this workflow apply-able to collections AND to items per collection, or for items in hashes.
    def call(fragment, doc)
      normal = [Default, SkipParse, ParseFilter, Set]
      typed = [Default, SkipParse, CreateObject, Prepare, Deserialize, ParseFilter, Set]

      if @binding.array?

        normal = [Default, ScalarIterate, ParseFilter, Set]
        typed = [Default, Iterate, ParseFilter, Set]

        return Pipeline[*@binding.typed? ? typed : normal].
                ("blaaaaaaa", fragment, doc, @binding)
      end

      Pipeline[*@binding.typed? ? typed : normal].
        ("blaaaaaaa", fragment, doc, @binding)
    end

    # A separated collection deserializer/populator allows us better dealing with populating/modifying
    # collections of models. (e.g. replace, update, push, etc.).
    # That also gives us a place to apply options like :parse_filter, etc. per item.
    class Collection < self
    private
      def deserialize(fragment, object)
        return deserializer.call(fragment, object)
      end
    end

    class Hash < self
    end
  end
end