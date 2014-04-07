require 'test_helper'

class IsRepresentableTest < BaseTest
  describe "representable: false, extend:" do
    representer!(:inject => :song_representer) do
      property :song,
        :representable => false,
        :extend        => song_representer
    end

    it "does extend but doesn't call #to_hash" do
      Struct.new(:song).new(song = Object.new).extend(representer).
        to_hash.must_equal("song" => song)
      song.must_be_kind_of Representable::Hash
    end
  end


  describe "representable: true, no extend:" do
    representer!(:inject => :song_representer) do
      property :song,
        :representable => true
    end

    it "doesn't extend but calls #to_hash" do
      song = Object.new
      song.instance_eval do
        def to_hash(*)
          1
        end
      end

      Struct.new(:song).new(song).extend(representer).
        to_hash.must_equal("song" => 1)
      song.wont_be_kind_of Representable::Hash
    end
  end

  # TODO: TEST implement for from_hash.
end