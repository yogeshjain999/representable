require 'test_helper'
require 'representable/coercion'

class VirtusCoercionTest < MiniTest::Spec
  class Song  # note that we don't define accessors for the properties here.
  end

  describe "Coercion with Virtus" do
    describe "on object level" do
      module SongRepresenter
        include Representable::JSON
        include Representable::Coercion
        property :composed_at,  :type => DateTime
        property :track,        :type => Integer
      end

      it "coerces properties in #from_json" do
        song = Song.new.extend(SongRepresenter).from_json("{\"composed_at\":\"November 18th, 1983\",\"track\":\"18\"}")
        assert_kind_of DateTime, song.composed_at
        assert_equal 18, song.track
        assert_equal DateTime.parse("Fri, 18 Nov 1983 00:00:00 +0000"), song.composed_at
      end
    end


    describe "on class level" do
      class ImmigrantSong
        include Representable::JSON
        include Representable::Coercion

        property :composed_at,  :type => DateTime, :default => "May 12th, 2012"
        property :track,        :type => Integer
      end

      it "coerces into the provided type" do
        song = ImmigrantSong.new.from_json("{\"composed_at\":\"November 18th, 1983\",\"track\":\"18\"}")
        assert_equal DateTime.parse("Fri, 18 Nov 1983 00:00:00 +0000"), song.composed_at
        assert_equal 18, song.track
      end

      it "respects the :default options" do
        song = ImmigrantSong.new.from_json("{}")
        assert_kind_of DateTime, song.composed_at
        assert_equal DateTime.parse("Mon, 12 May 2012 00:00:00 +0000"), song.composed_at
      end
    end

    require 'representable/decorator/coercion'
    describe "on decorator" do
      class SongRepresentation < Representable::Decorator
        include Representable::JSON
        include Representable::Decorator::Coercion

        property :composed_at, :type => DateTime
        property :title
      end

      it "coerces when parsing" do
        song = SongRepresentation.new(OpenStruct.new).from_json("{\"composed_at\":\"November 18th, 1983\", \"title\": \"Scarified\"}")
        song.must_be_kind_of OpenStruct
        song.composed_at.must_equal DateTime.parse("Fri, 18 Nov 1983")
        song.title.must_equal "Scarified"
      end

      it "coerces when rendering" do
        SongRepresentation.new(OpenStruct.new(:composed_at => "November 18th, 1983")).to_json.must_equal "{\"composed_at\":\"1983-11-18T00:00:00+00:00\"}"
      end
    end
  end
end
