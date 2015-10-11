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

class RenderPipelineOptionTest < MiniTest::Spec
  Album   = Struct.new(:id, :songs)
  NilToNA = ->(input, options) { input.nil? ? "n/a" : input }

  representer!(decorator: true) do
    property :id, render_pipeline: ->(options) do
      Representable::Pipeline[*render_functions.insert(2, NilToNA)]
    end# TODO: test if options are ok
  end

  it { representer.new(Album.new).extend(Representable::Debug).to_hash.must_equal({"id"=>"n/a"}) }
  it { representer.new(Album.new(1)).to_hash.must_equal({"id"=>1}) }
end