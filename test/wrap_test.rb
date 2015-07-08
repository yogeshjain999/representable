require "test_helper"

class WrapTest < MiniTest::Spec
  class HardcoreBand
    include Representable::Hash
  end

  class SoftcoreBand < HardcoreBand
  end

  let (:band) { HardcoreBand.new }

  it "returns false per default" do
    assert_equal nil, SoftcoreBand.new.send(:representation_wrap)
  end

  it "infers a printable class name if set to true" do
    HardcoreBand.representation_wrap = true
    assert_equal "hardcore_band", band.send(:representation_wrap)
  end

  it "can be set explicitely" do
    HardcoreBand.representation_wrap = "breach"
    assert_equal "breach", band.send(:representation_wrap)
  end

  for_formats(
    :hash => [Representable::Hash, {"Blink182"=>{"genre"=>"Pop"}}, {"Blink182"=>{"genre"=>"Poppunk"}}],
    :json => [Representable::JSON, "{\"Blink182\":{\"genre\":\"Pop\"}}", "{\"Blink182\":{\"genre\":\"Poppunk\"}}"],
    :xml  => [Representable::XML, "<Blink182><genre>Pop</genre></Blink182>", "<Blink182><genre>Poppunk</genre></Blink182>"],
    # :yaml => [Representable::YAML, "---\nBlink182:\n"], # TODO: fix YAML.
  ) do |format, mod, output, input|

    describe "[#{format}] dynamic wrap" do
      let (:band) { representer.prepare(Struct.new(:name, :genre).new("Blink", "Pop")) }
      let (:format) { format }

      representer!(:module => mod) do
        self.representation_wrap = lambda { |args| "#{name}#{args[:number]}" }
        property :genre
      end

      it { render(band, {:number => 182}).must_equal_document(output) }

      it { parse(band, input, {:number => 182}).genre.must_equal "Poppunk" } # TODO: better test. also, xml parses _any_ wrap.
    end
  end
end

class DisableWrapTest < MiniTest::Spec
  Band = Struct.new(:name)
  Album = Struct.new(:band)

  class BandDecorator < Representable::Decorator
    include Representable::Hash

    self.representation_wrap = :bands
    property :name
  end

  let (:band) { BandDecorator.prepare(Band.new("Social Distortion")) }

  it do
    band.to_hash.must_equal({"bands" => {"name"=>"Social Distortion"}})
    band.to_hash(wrap: false).must_equal({"name"=>"Social Distortion"})
  end


  class AlbumDecorator < Representable::Decorator
    include Representable::Hash

    self.representation_wrap = :albums

    property :band, decorator: BandDecorator, wrap: false
  end


  let (:album) { AlbumDecorator.prepare(Album.new(Band.new("Social Distortion"))) }

  it do
    album.to_hash.must_equal({"albums" => {"band" => {"name"=>"Social Distortion"}}})
  end
end

