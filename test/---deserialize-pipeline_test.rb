require "test_helper"

class DeserializePipelineTest < MiniTest::Spec
  Album  = Struct.new(:artist)
  Artist = Struct.new(:email)

  class ArtistPopulator
    include Uber::Callable

    def call(*args)
      raise args.inspect
    end
  end

  class Representer < Representable::Decorator
    include Representable::Hash

    property :artist, populator: Uber::Options::Value.new(ArtistPopulator) do
      property :email
    end
  end

  it do
    album = Album.new
    Representer.new(album).from_hash({artist: {email: "yo"}})
    puts album.inspect
  end
end