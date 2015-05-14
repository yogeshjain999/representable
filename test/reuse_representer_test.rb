require "test_helper"

class CachedTest < MiniTest::Spec
  # TODO: also test with feature(Cached)

  class SongRepresenter < Representable::Decorator
    include Representable::Hash
    include Representable::Cached

    property :title
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
    song  = Model::Song.new("Jailbreak")
    song2 = Model::Song.new("Southbound")
    album = Model::Album.new("Live And Dangerous", [song, song2, Model::Song.new("Emerald")])

    album2 = Model::Album.new("Louder And Even More Dangerous", [song2, song])



    representer = AlbumRepresenter.new(album)

    representer.to_hash.must_equal({"name"=>"Live And Dangerous",
      "songs"=>[{"title"=>"Jailbreak"}, {"title"=>"Southbound"}, {"title"=>"Emerald"}]}) # called in Deserializer/Serializer

    require "pp"
    # puts "???"
    # pp representer

    representer.update!(album2)

    puts "???"

    puts representer.to_hash # called in Deserializer/Serializer
  end
end