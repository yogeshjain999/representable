module Representable
  # Gives us Representer::for_collection and its configuration directive
  # ::collection_representer.
  module ForCollection
    def for_collection
      # this is done at run-time, not a big fan of this. however, it saves us from inheritance/self problems.
      @collection_representer ||= collection_representer!({})
    end

  private
    def collection_representer!(options)
      singular = self

      # DON'T make it inheritable as it would inherit the wrong singular.
      # representable_attrs[:collection_representer] = Module.new do
      Module.new do
        include Representable
        include Representable::JSON::Collection
        items options.merge(:extend => singular)
      end
    end

    def collection_representer(options={})
      @collection_representer = collection_representer!(options)
    end
  end
end