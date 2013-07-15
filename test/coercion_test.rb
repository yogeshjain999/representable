require 'test_helper'
require 'representable/coercion'
require 'representable/decorator/coercion'

class VirtusCoercionTest < MiniTest::Spec
  class Song  # note that we have to define accessors for the properties here.
    attr_accessor :title, :composed_at, :track
  end

  let (:date) { DateTime.parse("Fri, 18 Nov 1983 00:00:00 +0000") }

  describe "on object level" do
    module SongRepresenter
      include Representable::JSON
      include Representable::Coercion
      property :composed_at,  :type => DateTime
      property :track,        :type => Integer
      property :title # no coercion.
    end

    it "coerces properties in #from_json" do
      song = Song.new.extend(SongRepresenter).from_json('{"composed_at":"November 18th, 1983","track":"18","title":"Scarified"}')
      song.composed_at.must_equal date
      song.track.must_equal 18
      song.title.must_equal "Scarified"
    end

     it "coerces when rendering" do
       song = Song.new.extend(SongRepresenter)
       song.title       = "Scarified"
       song.composed_at = "Fri, 18 Nov 1983"

       song.to_hash.must_equal({"title" => "Scarified", "composed_at" => date})
     end
  end

  describe "on class level" do
    class ImmigrantSong
      include Representable::JSON
      include Representable::Coercion

      property :composed_at,  :type => DateTime, :default => "May 12th, 2012"
      property :track,        :type => Integer

      attr_accessor :composed_at, :track
    end

    it "coerces into the provided type" do
      song = ImmigrantSong.new.from_json("{\"composed_at\":\"November 18th, 1983\",\"track\":\"18\"}")
      song.composed_at.must_equal date
      song.track.must_equal 18
    end

    it "respects the :default options" do
      song = ImmigrantSong.new.from_json("{}")
      song.composed_at.must_equal DateTime.parse("Mon, 12 May 2012 00:00:00 +0000")
    end
  end

  describe "on decorator" do
    class SongRepresentation < Representable::Decorator
      include Representable::JSON
      include Representable::Coercion

      property :composed_at, :type => DateTime
      property :title
    end

    it "coerces when parsing" do
      song = SongRepresentation.new(OpenStruct.new).from_json("{\"composed_at\":\"November 18th, 1983\", \"title\": \"Scarified\"}")
      song.must_be_kind_of OpenStruct
      song.composed_at.must_equal date
      song.title.must_equal "Scarified"
    end

    it "coerses with inherited decorator" do
      song = Class.new(SongRepresentation).new(OpenStruct.new).from_json("{\"composed_at\":\"November 18th, 1983\", \"title\": \"Scarified\"}")
      song.composed_at.must_equal date
    end

    it "coerces when rendering" do
      SongRepresentation.new(
        OpenStruct.new(
          :composed_at  => "November 18th, 1983",
          :title        => "Scarified"
        )
      ).to_hash.must_equal({"composed_at"=>date, "title"=>"Scarified"})
    end
  end

  # DISCUSS: do we actually wanna have accessors in a decorator/module? i guess the better idea is to let coercion happen through from_/to_,
  # only, to make it as simple as possible.
  # describe "without serialization/deserialization" do
  #   let (:coercer_class) do
  #     class SongCoercer < Representable::Decorator
  #       include Representable::Decorator::Coercion

  #       property :composed_at, :type => DateTime
  #       property :title

  #       self
  #     end
  #   end

  #   it "coerces when setting" do
  #     coercer = coercer_class.new(song = OpenStruct.new)
  #     coercer.composed_at = "November 18th, 1983"
  #     #coercer.title       = "Scarified"

  #     song.composed_at.must_equal date
  #   end
  # end
end
