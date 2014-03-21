require 'test_helper'

class InstanceTest < GenericTest
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