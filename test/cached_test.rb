require "test_helper"
require 'ruby-prof'

class CachedTest < MiniTest::Spec
  # TODO: also test with feature(Cached)

  module Model
    Song  = Struct.new(:title, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name, :hidden_taste)
  end

  class SongRepresenter < Representable::Decorator
    include Representable::Hash
    feature Representable::Cached

    property :title, render_filter: lambda { |value, doc, options| "#{value}:#{options.user_options}" }, pass_options: true
    property :composer, class: Model::Artist do
      property :name
    end
  end

  class AlbumRepresenter < Representable::Decorator
    include Representable::Hash
    include Representable::Cached

    property :name
    collection :songs, decorator: SongRepresenter, class: Model::Song
  end


  let (:album_hash) { {"name"=>"Louder And Even More Dangerous", "songs"=>[{"title"=>"Southbound:{:volume=>10}"}, {"title"=>"Jailbreak:{:volume=>10}"}]} }

  it do
    song   = Model::Song.new("Jailbreak")
    song2  = Model::Song.new("Southbound")
    album  = Model::Album.new("Live And Dangerous", [song, song2, Model::Song.new("Emerald")])
    album2 = Model::Album.new("Louder And Even More Dangerous", [song2, song])

    representer = AlbumRepresenter.new(album)

    # makes sure options are passed correctly.

    representer.to_hash(volume: 9).must_equal({"name"=>"Live And Dangerous",
      "songs"=>[{"title"=>"Jailbreak:{:volume=>9}"}, {"title"=>"Southbound:{:volume=>9}"}, {"title"=>"Emerald:{:volume=>9}"}]}) # called in Deserializer/Serializer

    # representer becomes reusable as it is stateless.
    representer.update!(album2)

    # makes sure options are passed correctly.
    representer.to_hash(volume:10).must_equal(album_hash)
  end

  it "deser" do
    album_hash = {
      "name"=>"Louder And Even More Dangerous",
      "songs"=>[
        {"title"=>"Southbound", "composer"=>{"name"=>"Lynott"}},
        {"title"=>"Jailbreak", "composer"=>{"name"=>"Phil Lynott"}},
        {"title"=>"Emerald"}
      ]
    }



    representer = AlbumRepresenter.new(Model::Album.new)

    RubyProf.start
      representer.from_hash(album_hash)
    res = RubyProf.stop

    printer = RubyProf::FlatPrinter.new(res)

    data = StringIO.new
    printer.print(data)
    data = data.string

    # only 2 nested decorators are instantiated, Song, and Artist.
    data.must_match "2   <Class::Representable::Decorator>#prepare"
    # a total of 5 properties in the object graph.
    data.must_match "5   Representable::Binding#initialize"
    # three mappers for Album, Song, composer
    data.must_match "3   Representable::Mapper::Methods#initialize"
    # 6 deserializers as the songs collection uses 2.
    data.must_match "6   Representable::Deserializer#initialize"
    # one populater for every property.
    data.must_match "5   Representable::Populator#initialize"
    # printer.print(STDOUT)
  end
end