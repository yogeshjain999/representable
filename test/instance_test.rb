require 'test_helper'

class InstanceTest < GenericTest
  Song = Struct.new(:id, :title)
  Song.class_eval do
    def self.find(id)
      new(id, "Invincible")
    end
  end

# TODO: use *args in from_hash.
# DISCUSS: do we need parse_strategy?
  describe "property with :instance" do
    representer!(:inject => :song_representer) do
      property :song,
        :instance => lambda { |fragment| fragment["id"] == song.id ? nil : Song.find(fragment["id"]) },
        :extend => song_representer
    end

    it { OpenStruct.new(:song => Song.new(1, "The Answer Is Still No")).extend(representer).
      from_hash("song" => {"id" => 1}).song.must_equal Song.new(1, "The Answer Is Still No") }

    it { OpenStruct.new(:song => Song.new(1, "The Answer Is Still No")).extend(representer).
      from_hash("song" => {"id" => 2}).song.must_equal Song.new(2, "Invincible") }
  end


  describe "collection with :instance" do
    representer!(:inject => :song_representer) do
      collection :songs,
        :instance => lambda { |fragment, i|

          puts "====  ==========#{fragment}: #{i.inspect} => #{songs[i].inspect}"

        fragment["id"] == songs[i].id ? songs[i] : Song.find(fragment["id"]) }, # let's not allow returning nil anymore. make sure we can still do everything as with nil. also, let's remove parse_strategy: sync.
        :extend => song_representer
        #:parse_strategy => :sync
    end
    # TODO: create object when list[i] nil!
    # TODO: check object_id.
    # TODO: make sure instance{nil} works in collection.

# problem: when returning nil in this lambda WITHOUT parse: true, the original model's collection is empty and object.call in #instance_for doesn't work, so we still try to create a brand-new object.
    it( "sds") {
puts "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\collection"
      Struct.new(:songs).new([
      Song.new(1, "The Answer Is Still No"),
      Song.new(2, "")]).
        extend(representer).
        from_hash("songs" => [{"id" => 2},{"id" => 2, "title"=>"The Answer Is Still No"}]).songs.must_equal [
          Song.new(2, "Invincible"), Song.new(2, "The Answer Is Still No")] }

    # it { OpenStruct.new(:song => Song.new(1, "The Answer Is Still No")).extend(representer).
    #   from_hash("song" => {"id" => 2}).song.must_equal Song.new(2, "Invincible") }
  end


  describe "property with instance: { nil }" do # TODO: introduce :representable option?
    representer!(:inject => :song_representer) do
      property :song, :instance => lambda { |*| nil }, :extend => song_representer
    end

    let (:hit) { hit = OpenStruct.new(:song => song).extend(representer) }

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
end