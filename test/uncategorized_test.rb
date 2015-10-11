require "test_helper"

class StopWhenIncomingObjectFragmentIsNilTest < MiniTest::Spec
  Album = Struct.new(:id, :songs)
  Song  = Struct.new(:title)

  representer!(decorator: true) do
    property :id
    collection :songs, class: Song, parse_pipeline: ->(options) { # TODO: test if :doc is set for parsing. test if options are ok and contain :user_options!
                Representable::Pipeline[*parse_functions.insert(3, Representable::StopOnNil)]
                } do
      property :title
    end
  end

  it do
    album = Album.new
    representer.new(album).from_hash({"id"=>1, "songs"=>[{"title"=>"Walkie Talkie"}]}).songs.must_equal [Song.new("Walkie Talkie")]
  end

  it do
    album = Album.new(2, ["original"])
    representer.new(album).from_hash({"id"=>1, "songs"=>nil}).songs.must_equal ["original"]
  end

end