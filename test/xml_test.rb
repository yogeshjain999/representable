require 'test_helper'


class XmlPublicMethodsTest < Minitest::Spec
  Band = Struct.new(:id, :name, :genre, :uid, :logo, :songs, :scores, :manager)
  IoFile = Struct.new(:blob, :file)
  MusicSong = Struct.new(:title, :track)
  Person    = Struct.new(:email)

  class ManagerRepresenter < Representable::Decorator
    include Representable::XML

    property :email
  end

  class BandRepresenter < Representable::Decorator
    include Representable::XML
    self.representation_wrap = :artists

    property :id, attribute: true
    property :uid, attribute: true, as: :uuid

    property :name, as: :bandName
    property :genre
    collection :scores

    property :logo, class: IoFile do
      property :blob
      property :file, as: :fileName, attribute: true
    end

    collection :songs, as: :hit, class: MusicSong do
      property :title
      property :track, attribute: true
    end

    property :manager, decorator: ManagerRepresenter, as: :boss, class: Person
  end

  let(:data) { %{
    <artists id="1" uuid="4711">
      <bandName>Rancid</bandName>
      <genre>Punk</genre>
      <scores>6</scores><scores>10</scores><scores>9</scores>
      <io_file fileName=\"logo.png\"><blob>0x1</blob></io_file>

      <hit track=\"1\"><title>The Wolf</title></hit>
      <hit track=\"2\"><title>Cocktails</title></hit>

      <person><email>kt@trb.to</email></person>
    </artists>}
  }

  #---
  # to_xml
  let(:band) { Band.new(1, "Rancid", "Punk", "4711", IoFile.new("0x1", "logo.png"),
    [ MusicSong.new("The Wolf", 1), MusicSong.new("Cocktails", 2) ],
    [ 6, 10, 9 ],
    Person.new("kt@trb.to")
  ) }

  it { BandRepresenter.new(band).to_xml.must_xml data }

  #---
  # from_xml
  describe "#from_xml" do
    let(:incoming_document) { %{
      <artists id="1" uuid="4711">
        <bandName>Rancid</bandName>
        <genre>Punk</genre>
        <scores>6</scores><scores>10</scores><scores>9</scores>
        <logo fileName=\"logo.png\"><blob>0x1</blob></logo>

        <hit track=\"1\"><title>The Wolf</title></hit>
        <hit track=\"2\"><title>Cocktails</title></hit>

        <boss><email>kt@trb.to</email></boss>
      </artists>}
    }

    it do
      band = Band.new

      BandRepresenter.new(band).from_xml(incoming_document)

      band.id.must_equal "1"
      band.uid.must_equal "4711"
      band.genre.must_equal "Punk"
      band.scores.must_equal ["6", "10", "9"]
      band.logo.inspect.must_equal %{#<struct XmlPublicMethodsTest::IoFile blob="0x1", file="logo.png">}
      band.songs.inspect.must_equal %{[#<struct XmlPublicMethodsTest::MusicSong title="The Wolf", track="1">, #<struct XmlPublicMethodsTest::MusicSong title="Cocktails", track="2">]}
      band.manager.inspect.must_equal %{#<struct XmlPublicMethodsTest::Person email="kt@trb.to">}
    end
  end

end

class CDataBand
  class CData < Representable::XML::Binding
    def serialize_node(parent, value)
      parent << Nokogiri::XML::CDATA.new(parent, represented.name)
    end
  end

  include Representable::XML
  property :name, :binding => lambda { |*args| CData.new(*args) }#getter: lambda { |opt| Nokogiri::XML::CDATA.new(opt[:doc], name) }
  attr_accessor :name

  def initialize(name=nil)
    name and self.name = name
  end
end

class TypedPropertyTest < MiniTest::Spec

  # TODO:property :group, :class => Band
  # :class
  # where to mixin DCI?
  describe ":class => Item" do


    describe "#to_xml" do


      it "doesn't escape and wrap string from Band#to_node" do
        band = Band.new("Bad Religion")
        band.instance_eval do
          def to_node(*)
            "<band>Baaaad Religion</band>"
          end
        end

        assert_xml_equal %{<album><band>Baaaad Religion</band></album>}, Album.new(band).extend(AlbumRepresenter).to_xml
      end
    end

    describe "#to_xml with CDATA" do
      it "wraps Band name in CDATA#to_xml" do
        band = CDataBand.new("Bad Religion")
        album = Album.new(band).extend(AlbumRepresenter)

        assert_xml_equal %{<album>
         <c_data_band>
           <name><![CDATA[Bad Religion]]></name>
         </c_data_band>
       </album>}, album.to_xml
      end
    end
  end
end


class XMLCollectionTest < MiniTest::Spec
  Band        = Struct.new(:name)
  Compilation = Struct.new(:bands)

  class BandRepresenter < Representable::Decorator
    include Representable::XML
    property :name
  end

  #---
  #- :as, :decorator, :class
  describe ":class => Band, :as => :band, :collection => true" do
    class CompilationRepresenter < Representable::Decorator
      include Representable::XML
      collection :bands, class: Band, as: :group, decorator: BandRepresenter
    end

    describe "#from_xml" do
      it "pushes collection items to array" do
        cd = CompilationRepresenter.new(Compilation.new).from_xml(%{
          <compilation>
            <group><name>Diesel Boy</name></group>
            <group><name>Cobra Skulls</name></group>
          </compilation>
        })
        assert_equal ["Cobra Skulls", "Diesel Boy"], cd.bands.map(&:name).sort
      end
    end

    it "responds to #to_xml" do
      cd = Compilation.new([Band.new("Diesel Boy"), Band.new("Bad Religion")])

      CompilationRepresenter.new(cd).to_xml.must_equal_xml %{<compilation>
        <group><name>Diesel Boy</name></group>
        <group><name>Bad Religion</name></group>
      </compilation>}
    end
  end


  describe ":as" do
    let(:xml_doc) {
      Module.new do
        include Representable::XML
        collection :songs, :as => :song
      end }

    it "collects untyped items" do
      album = Album.new.extend(xml_doc).from_xml(%{
        <album>
          <song>Two Kevins</song>
          <song>Wright and Rong</song>
          <song>Laundry Basket</song>
        </album>
      })
      assert_equal ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort, album.songs.sort
    end
  end


  describe ":wrap" do
    let(:album) { Album.new.extend(xml_doc) }
    let(:xml_doc) {
      Module.new do
        include Representable::XML
        collection :songs, :as => :song, :wrap => :songs
      end }

    describe "#from_xml" do
      it "finds items in wrapped collection" do
        album.from_xml(%{
          <album>
            <songs>
              <song>Two Kevins</song>
              <song>Wright and Rong</song>
              <song>Laundry Basket</song>
            </songs>
          </album>
        })
        assert_equal ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort, album.songs.sort
      end
    end

    describe "#to_xml" do
      it "wraps items" do
        album.songs = ["Laundry Basket", "Two Kevins", "Wright and Rong"]
        assert_xml_equal %{
          <album>
            <songs>
              <song>Laundry Basket</song>
              <song>Two Kevins</song>
              <song>Wright and Rong</song>
            </songs>
          </album>
        }, album.to_xml
      end
    end
  end

  require 'representable/xml/hash'
  class LonelyRepresenterTest < MiniTest::Spec
    # TODO: where is the XML::Hash test?
    module SongRepresenter
      include Representable::XML
      property :name
      self.representation_wrap = :song
    end

    let(:decorator) { rpr = representer; Class.new(Representable::Decorator) { include Representable::XML; include rpr } }

    describe "XML::Collection" do
      describe "with contained objects" do
        representer!(:module => Representable::XML::Collection)  do
          items :class => Song, :extend => SongRepresenter
          self.representation_wrap= :songs
        end

        let(:songs) { [Song.new("Days Go By"), Song.new("Can't Take Them All")] }
        let(:xml_doc)   { "<songs><song><name>Days Go By</name></song><song><name>Can't Take Them All</name></song></songs>" }

        it "renders array" do
          songs.extend(representer).to_xml.must_equal_xml xml_doc
        end

        it "renders array with decorator" do
          decorator.new(songs).to_xml.must_equal_xml xml_doc
        end

        it "parses array" do
          [].extend(representer).from_xml(xml_doc).must_equal songs
        end

        it "parses array with decorator" do
          decorator.new([]).from_xml(xml_doc).must_equal songs
        end
      end
    end

    describe "XML::AttributeHash" do  # TODO: move to HashTest.
      representer!(:module => Representable::XML::AttributeHash) do
        self.representation_wrap= :songs
      end

      let(:songs) { {"one" => "Graveyards", "two" => "Can't Take Them All"} }
      let(:xml_doc)   { "<favs one=\"Graveyards\" two=\"Can't Take Them All\" />" }

      describe "#to_xml" do
        it "renders hash" do
          songs.extend(representer).to_xml.must_equal_xml xml_doc
        end

        it "respects :exclude" do
          assert_xml_equal "<favs two=\"Can't Take Them All\" />", songs.extend(representer).to_xml(:exclude => [:one])
        end

        it "respects :include" do
          assert_xml_equal "<favs two=\"Can't Take Them All\" />", songs.extend(representer).to_xml(:include => [:two])
        end

        it "renders hash with decorator" do
          decorator.new(songs).to_xml.must_equal_xml xml_doc
        end
      end

      describe "#from_json" do
        it "returns hash" do
          {}.extend(representer).from_xml(xml_doc).must_equal songs
        end

        it "respects :exclude" do
          assert_equal({"two" => "Can't Take Them All"}, {}.extend(representer).from_xml(xml_doc, :exclude => [:one]))
        end

        it "respects :include" do
          assert_equal({"one" => "Graveyards"}, {}.extend(representer).from_xml(xml_doc, :include => [:one]))
        end

        it "parses hash with decorator" do
          decorator.new({}).from_xml(xml_doc).must_equal songs
        end
      end
    end
  end
end

class XmlHashTest < MiniTest::Spec
  # scalar, no object
  describe "plain text" do
    representer!(module: Representable::XML) do
      hash :songs
    end

    let(:doc) { "<open_struct><first>The Gargoyle</first><second>Bronx</second></open_struct>" }

    # to_xml
    it { OpenStruct.new(songs: {"first" => "The Gargoyle", "second" => "Bronx"}).extend(representer).to_xml.must_equal_xml(doc) }
    # FIXME: this NEVER worked!
    # it { OpenStruct.new.extend(representer).from_xml(doc).songs.must_equal({"first" => "The Gargoyle", "second" => "Bronx"}) }
  end

  describe "with objects" do
    representer!(module: Representable::XML) do
      hash :songs, class: OpenStruct do
        property :title
      end
    end

    let(:doc) { "<open_struct>
  <open_struct>
    <title>The Gargoyle</title>
  </open_struct>
  <open_struct>
    <title>Bronx</title>
  </open_struct>
</open_struct>" }

    # to_xml
    it { OpenStruct.new(songs: {"first" => OpenStruct.new(title: "The Gargoyle"), "second" => OpenStruct.new(title: "Bronx")}).extend(representer).to_xml.must_equal_xml(doc) }
    # FIXME: this NEVER worked!
    # it { OpenStruct.new.extend(representer).from_xml(doc).songs.must_equal({"first" => "The Gargoyle", "second" => "Bronx"}) }
  end
end
