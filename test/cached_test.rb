require "test_helper"

class CachedTest < MiniTest::Spec
  # TODO: also test with feature(Cached)

  class SongRepresenter < Representable::Decorator
    include Representable::Hash
    include Representable::Cached

    property :title, render_filter: lambda { |value, doc, options| "#{value}:#{options.user_options}" }, pass_options: true
  end

  class AlbumRepresenter < Representable::Decorator
    include Representable::Hash
    include Representable::Cached

    property :name
    collection :songs, decorator: SongRepresenter
  end



  module Model
    Song  = Struct.new(:title, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name, :hidden_taste)
  end

  it do
    song   = Model::Song.new("Jailbreak")
    song2  = Model::Song.new("Southbound")
    album  = Model::Album.new("Live And Dangerous", [song, song2, Model::Song.new("Emerald")])
    album2 = Model::Album.new("Louder And Even More Dangerous", [song2, song])

    representer = AlbumRepresenter.new(album)

    representer.to_hash(volume: 9).must_equal({"name"=>"Live And Dangerous",
      "songs"=>[{"title"=>"Jailbreak:{:volume=>9}"}, {"title"=>"Southbound:{:volume=>9}"}, {"title"=>"Emerald:{:volume=>9}"}]}) # called in Deserializer/Serializer

    # representer becomes reusable as it is stateless.
    representer.update!(album2)
    representer.to_hash(volume:10).must_equal({"name"=>"Louder And Even More Dangerous", "songs"=>[{"title"=>"Southbound:{:volume=>10}"}, {"title"=>"Jailbreak:{:volume=>10}"}]})
  end
end