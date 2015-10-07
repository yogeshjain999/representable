require "test_helper"

class DeserializePipelineTest < MiniTest::Spec
  Album  = Struct.new(:artist, :songs)
  Artist = Struct.new(:email)
  Song   = Struct.new(:title)

  # tests [Collect[Instance, Prepare, Deserialize], Setter]
  class Representer < Representable::Decorator
    include Representable::Hash

    # property :artist, populator: Uber::Options::Value.new(ArtistPopulator.new), pass_options:true do
    #   property :email
    # end
    # DISCUSS: rename to populator_pipeline ?
    collection :songs, parse_pipeline: ->(*) { [Collect[Instance, Prepare, Deserialize], Setter] }, instance: :instance!, exec_context: :decorator, pass_options: true do
      property :title
    end

    def instance!(*options)
      puts "@@@@@ #{options.inspect}"
      Song.new
    end

    def songs=(array)
      represented.songs=array
    end
  end

  it do
    skip "TODO: implement :parse_pipeline and :render_pipeline, and before/after/replace semantics"
    album = Album.new
    Representer.new(album).from_hash({"artist"=>{"email"=>"yo"}, "songs"=>[{"title"=>"Affliction"}, {"title"=>"Dream Beater"}]})
    album.songs.must_equal([Song.new("Affliction"), Song.new("Dream Beater")])
    puts album.inspect
  end
end