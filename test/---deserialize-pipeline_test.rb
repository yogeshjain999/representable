require "test_helper"

class DeserializePipelineTest < MiniTest::Spec
  Album  = Struct.new(:artist, :songs)
  Artist = Struct.new(:email)
  Song   = Struct.new(:title)

  # this is gonna implement a simple pipeline that we can reuse across the entire gem.
  class ArtistPopulator
    include Uber::Callable



    def call(represented, fragment, options)
      result  = fragment != Representable::Binding::FragmentNotFound
      return unless result # this is one pipeline step.
      # here, another step could be plugged in, e.g. :default.

      represented.artist = options.binding.representer_module_for(nil).new(Artist.new).from_hash(fragment)
    end
  end

  # tests [Collect[Instance, Prepare, Deserialize], Setter]
  class Representer < Representable::Decorator
    include Representable::Hash

    # property :artist, populator: Uber::Options::Value.new(ArtistPopulator.new), pass_options:true do
    #   property :email
    # end
    # DISCUSS: rename to populator_pipeline ?
    collection :songs, parse_pipeline: -> (*) { [Collect[Instance, Prepare, Deserialize], Setter] }, instance: :deserialize!, exec_context: :decorator do
      property :title
    end

    def deserialize!(fragment, *args)
      Song.new
    end

    def songs=(array)
      represented.songs=array
    end
  end

  it do
    album = Album.new
    Representer.new(album).from_hash({"artist"=>{"email"=>"yo"}, "songs"=>[{"title"=>"Affliction"}, {"title"=>"Dream Beater"}]})
    album.songs.must_equal([Song.new("Affliction"), Song.new("Dream Beater")])
    puts album.inspect
  end
end

# [:not_found?, :default, :deserialize].("yo")

NotFound = ->(fragment) do
  return Representable::Pipeline::Stop if fragment == Representable::Binding::FragmentNotFound
  fragment
end

Default = ->(fragment) do
  fragment
end

Deserialize = ->(fragment) do
  DeserializePipelineTest::Artist.new
end

Sety = ->(object) do
  puts "@@@@@ setting #{object.inspect}"
end

puts "yo"
Representable::Pipeline[NotFound, Default, Deserialize, Sety].(nil, "yo")

puts "Representable::Binding::FragmentNotFound"
Representable::Pipeline[NotFound, Default, Deserialize, Sety].(nil, Representable::Binding::FragmentNotFound)