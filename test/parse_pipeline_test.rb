require "test_helper"

class ParsePipelineTest < MiniTest::Spec
  Album  = Struct.new(:artist, :songs)
  Artist = Struct.new(:email)
  Song   = Struct.new(:title)


  # class StopWhenIncomingObjectFragmentIsNilTest < MiniTest::Spec
  #   Album = Struct.new(:id, :songs)
  #   Song  = Struct.new(:title)

  #   representer!(decorator: true) do
  #     property :id
  #     collection :songs, class: Song, parse_pipeline: ->(input, options) { # TODO: test if :doc is set for parsing. test if options are ok and contain :user_options!
  #                 Representable::Pipeline[*parse_functions.insert(3, Representable::StopOnNil)]
  #                 } do
  #       property :title
  #     end
  #   end

  #   it do
  #     album = Album.new
  #     representer.new(album).from_hash({"id"=>1, "songs"=>[{"title"=>"Walkie Talkie"}]}).songs.must_equal [Song.new("Walkie Talkie")]
  #   end

  #   it do
  #     album = Album.new(2, ["original"])
  #     representer.new(album).from_hash({"id"=>1, "songs"=>nil}).songs.must_equal ["original"]
  #   end

  # end

  describe "transforming nil to [] when parsing" do
    representer!(decorator: true) do
      collection :songs,
          parse_pipeline: ->(input, options) {

            Representable::Pipeline[
              *Representable::Pipeline::Insert.(
                parse_functions,
                ->(input, options) { input.nil? ? [] : input },
                replace: Representable::OverwriteOnNil
              )
            ]
          } do
        property :title
      end
    end

    it do
      representer.new(album = Album.new).from_hash("songs"=>[])
      album.songs.must_equal []
    end
  end


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