module Representable
  Default = ->(fragment, doc, binding) do
    # return Representable::Pipeline::Stop if fragment == Representable::Binding::FragmentNotFound
    if fragment == Representable::Binding::FragmentNotFound
      return Representable::Pipeline::Stop unless binding.has_default?
      return binding[:default]
    end

    fragment
  end

  SkipParse = ->(fragment, doc, binding) do
    return Pipeline::Stop if binding.evaluate_option(:skip_parse, fragment)
    fragment
  end

  Deserialize = ->(fragment, doc, binding) do
    # use a Deserializer to transform fragment to/into object.
    binding.send(:deserializer).call(fragment)
  end

  ParseFilter = ->(value, doc, binding) do
    binding.parse_filter(value, doc) # FIXME: nested pipeline!
  end

  Set = ->(value, doc, binding) do
    binding.set(value)
  end

  class Populator
    def initialize(binding)
      @binding = binding
    end

    # goal of this is to have this workflow apply-able to collections AND to items per collection, or for items in hashes.
    def call(fragment, doc)
      Pipeline[Default, SkipParse, Deserialize, ParseFilter, Set].
        ("blaaaaaaa", fragment, doc, @binding)
    end

    # A separated collection deserializer/populator allows us better dealing with populating/modifying
    # collections of models. (e.g. replace, update, push, etc.).
    # That also gives us a place to apply options like :parse_filter, etc. per item.
    class Collection < self
    private
      def deserialize(fragment)
        return deserializer.call(fragment)
      end
    end

    class Hash < self
    end
  end
end