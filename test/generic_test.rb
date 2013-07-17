require 'test_helper'

class GenericTest < MiniTest::Spec
# one day, this file will contain all engine-independent test cases. one day...
  let (:new_album)  { OpenStruct.new.extend(representer) }
  let (:album)      { OpenStruct.new(:songs => ["Fuck Armageddon"]).extend(representer) }
  #let (:song) { OpenStruct.new(:title) }

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
end