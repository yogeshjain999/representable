require 'test_helper'

class GenericTest < MiniTest::Spec
# one day, this file will contain all engine-independent test cases. one day...
  let (:new_album)  { OpenStruct.new.extend(representer) }
  let (:album)      { OpenStruct.new(:songs => ["Fuck Armageddon"]).extend(representer) }
  let (:song) { OpenStruct.new(:title => "Resist Stance").extend(song_representer) }
  let (:song_representer) { Module.new do include Representable::Hash; property :title end  }


  describe "::collection" do
    representer! do
      collection :songs
    end

    it "initializes property with empty array" do
      new_album.from_hash({})
      new_album.songs.must_equal [] # DISCUSS: do we really want this?
    end

    it "overrides property with empty array" do
      album.from_hash({})
      album.songs.must_equal [] # DISCUSS: do we really want this?
    end
  end


  describe ":representable with property" do # TODO: introduce :representable option?
    representer! do
      property :song, :instance => lambda { |*| nil }
    end

    let (:hit) { hit = OpenStruct.new(:song => song).extend(representer) } # note that song is already representable.

    it "calls #to_hash on song instance, nothing else" do
      hit.to_hash.must_equal("song"=>{"title"=>"Resist Stance"})
    end

    it "calls #from_hash on the existing song instance, nothing else" do
      song_id = hit.song.object_id
      hit.from_hash("song"=>{"title"=>"Suffer"})
      hit.song.title.must_equal "Suffer"
      hit.song.object_id.must_equal song_id
    end
  end


  describe ":representable with collection" do # TODO: introduce :representable option?
    representer! do
      collection :songs, :instance => lambda { |*| nil }
    end
    let (:album) { OpenStruct.new(:songs => [song]).extend(representer) }

    it "calls #to_hash on song instances, nothing else" do
      album.to_hash.must_equal("songs"=>[{"title"=>"Resist Stance"}])
    end

    it "calls #from_hash on the existing song instance, nothing else" do
      album.songs.instance_eval do
        def from_hash(items, *args)
          #puts items #=> {"title"=>"Suffer"}
          first.from_hash(items)  # example how you can use this.
        end
      end

      song = album.songs.first
      song_id = song.object_id
      album.from_hash("songs"=>[{"title"=>"Suffer"}])
      song.title.must_equal "Suffer"
      song.object_id.must_equal song_id
    end
  end
end