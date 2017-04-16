require "test_helper"

# <lib:library
#    xmlns:lib="http://eric.van-der-vlist.com/ns/library"
#    xmlns:hr="http://eric.van-der-vlist.com/ns/person">
#   <lib:book id="b0836217462" available="true">
#    <lib:isbn>0836217462</lib:isbn>
#    <lib:title xml:lang="en">Being a Dog Is a Full-Time Job</lib:title>
#    <hr:author id="CMS">
#     <hr:name>Charles M Schulz</hr:name>
#     <hr:born>1922-11-26</hr:born>
#     <hr:dead>2000-02-12</hr:dead>
#    </hr:author>
#    <lib:character id="PP">
#     <hr:name>Peppermint Patty</hr:name>
#     <hr:born>1966-08-22</hr:born>
#     <lib:qualification>bold, brash and tomboyish</lib:qualification>
#     </lib:character>
#    <lib:character id="Snoopy">
#     <hr:name>Snoopy</hr:name>
#     <hr:born>1950-10-04</hr:born>
#     <lib:qualification>extroverted beagle</lib:qualification>
#    </lib:character>
#    <lib:character id="Schroeder">
#     <hr:name>Schroeder</hr:name>
#     <hr:born>1951-05-30</hr:born>
#     <lib:qualification>brought classical music to the Peanuts strip
#                   </lib:qualification>
#    </lib:character>
#    <lib:character id="Lucy">
#     <hr:name>Lucy</hr:name>
#     <hr:born>1952-03-03</hr:born>
#     <lib:qualification>bossy, crabby and selfish</lib:qualification>
#    </lib:character>
#   </lib:book>
#  </lib:library>

  # Theoretically, every property (scalar) needs/should have a namespace.
  # property :name, namespace: "http://eric.van-der-vlist.com/ns/person"
  # # This is implicit if contained:
  # class Person < Decorator
  #   namespace: "http://eric.van-der-vlist.com/ns/person"
  #   property :name #, namespace: "http://eric.van-der-vlist.com/ns/person"
  # end
  # class Library
  #   namespace "http://eric.van-der-vlist.com/ns/library"

  #   namespace_def lib:    "http://eric.van-der-vlist.com/ns/library"
  #   namespace_def person: "http://eric.van-der-vlist.com/ns/person"
  #   # namespace_def person: Person

  #   property :person, decorator: Person
  # end
class NamespaceXMLTest < Minitest::Spec
  module Model
    Library = Struct.new(:book)
    Book = Struct.new(:id, :isbn)
  end

  let (:book) { Model::Book.new(1, 666) }

  class Library < Representable::Decorator
    feature Representable::XML
    feature Representable::XML::Namespace

    namespace "http://eric.van-der-vlist.com/ns/library"

    property :book do
      namespace "http://eric.van-der-vlist.com/ns/library"

      property :id,  attribute: true
      property :isbn
    end
  end


  # default namespace for library
  it "what" do
    Library.new(Model::Library.new(book)).to_xml.must_equal %{<library xmlns=\"http://eric.van-der-vlist.com/ns/library\">
  <book id=\"1\">
    <isbn>666</isbn>
  </book>
</library>}
  end
end

class Namespace2XMLTest < Minitest::Spec
  module Model
    Library   = Struct.new(:book)
    Book      = Struct.new(:id, :isbn, :author, :character)
    Character = Struct.new(:name, :born, :qualification)
  end

  let (:book) { Model::Book.new(1, 666, Model::Character.new("Fowler"), [Model::Character.new("Frau Java", 1991, "typed")]) }

  class Library < Representable::Decorator
    feature Representable::XML
    feature Representable::XML::Namespace

    namespace "http://eric.van-der-vlist.com/ns/library"
    namespace_def lib: "http://eric.van-der-vlist.com/ns/library"
    namespace_def hr: "http://eric.van-der-vlist.com/ns/person"

    property :book do
      namespace "http://eric.van-der-vlist.com/ns/library"

      property :id,  attribute: true
      property :isbn

      property :author do
        namespace "http://eric.van-der-vlist.com/ns/person"

        property :name
        property :born
      end

      collection :character do
        namespace "http://eric.van-der-vlist.com/ns/library"

        property :qualification

        # TODO: this should be referenceable to reduce redundancy!
        property :name, namespace: "http://eric.van-der-vlist.com/ns/person"
        property :born, namespace: "http://eric.van-der-vlist.com/ns/person"
      end
    end
  end

  it "what" do
    Library.new(Model::Library.new(book)).to_xml.must_equal %{<lib:library xmlns:lib=\"http://eric.van-der-vlist.com/ns/library\" xmlns:hr=\"http://eric.van-der-vlist.com/ns/person\">
  <lib:book id=\"1\">
    <lib:isbn>666</lib:isbn>
    <hr:author>
      <hr:name>Fowler</hr:name>
    </hr:author>
    <lib:character>
      <lib:qualification>typed</lib:qualification>
      <hr:name>Frau Java</hr:name>
      <hr:born>1991</hr:born>
    </lib:character>
  </lib:book>
</lib:library>}
  end
end


# class XmlNamespaceTest < Minitest::Spec




#   Band = Struct.new(:name, :song, :genre)
#   Song = Struct.new(:name)
#   let(:band) { Band.new("Nofx", "Linoleum", "Punk") }
#   let(:song) { Song.new("The Brews") }
# end

# class XmlNamespaceWithNamespaceAndPropertyTest < XmlNamespaceTest
#   class BandRepresenter < Representable::Decorator
#     include Representable::XML
#     include Representable::XML::Namespace
#     self.representation_wrap = :band

#     # namespaces music: "http://test.org/music"
#     namespace "http://test.org/band" # could also be `wrap :band, namespace: :music`

#     property :name#, as: "music:name"
#     property :genre, attribute: true
#   end

#   # no prefix, only xmlns attribute.
#   it do
#     BandRepresenter.new(band).to_xml.must_equal %{<band xmlns="http://test.org/band" genre="Punk">
#   <name>Nofx</name>
# </band>}
#   end

#   # with namespace prefix
#   it do
#     BandRepresenter.new(band).to_xml(namespace: :music).must_equal %{<music:band xmlns:music="http://test.org/band" genre="Punk">
#   <music:name>Nofx</music:name>
# </music:band>}
#   end

#   # with :namespace and :show_definition
#   it do
#     BandRepresenter.new(band).to_xml(namespace: :music).must_equal %{<music:band xmlns:music="http://test.org/band" genre="Punk">
#   <music:name>Nofx</music:name>
# </music:band>}
#   end

#   #---
#   #- from_xml
#   it do
#     BandRepresenter.new(band).from_xml(%{

# <music:band xmlns:music="http://test.org/music">
#   <name>Pulley not namespaced</name>
#   <music:name>Pulley</name>
# </music:band>})

#     band.name.must_equal "Pulley not namespaced"
#   end

#   it do
#     BandRepresenter.new(band).from_xml(%{

# <music:band xmlns:music="http://test.org/music">
#   <name>Pulley not namespaced</name>
#   <music:name>Pulley</name>
# </music:band>}, namespace: :music)

#     band.name.must_equal "Pulley"
#   end

#   #---
#   #- Nested
#   Label = Struct.new(:band, :song, :group)

#   class LabelRepresenter < Representable::Decorator
#     include Representable::XML
#     # include Representable::XML::Namespace
#     self.representation_wrap = :label

#     property :band, decorator: BandRepresenter
#   end

#   it do
#     LabelRepresenter.new(Label.new(band)).to_xml.must_equal %{<label>
#   <band xmlns=\"http://test.org/band\" genre="Punk">
#     <name>Nofx</name>
#   </band>
# </label>}
#   end

#   class SongRepresenter < Representable::Decorator
#     include Representable::XML
#     include Representable::XML::Namespace
#     self.representation_wrap = :song

#     # namespaces music: "http://test.org/music"
#     namespace "http://song"

#     property :name
#   end

#   class NamespaceLabelRepresenter < Representable::Decorator
#     include Representable::XML
#     include Representable::XML::Namespace
#     self.representation_wrap = :label

#     # namespace "http://Override"

#     property :band, decorator: BandRepresenter, namespace: "nsBand", class: XmlNamespaceTest::Band # defines ::namespace
#     property :song, decorator: SongRepresenter, namespace: "nsSong", class: Song
#     property :group, decorator: BandRepresenter # this will print the namespace definition in <group xmlns="http://test.org/band">
#     # FIXME: why isn't that <group>?
#   end

#   it do
#     NamespaceLabelRepresenter.new(Label.new(band, song, Band.new("El Grupo"))).to_xml.must_equal(
# %{<label xmlns:nsBand="http://test.org/band" xmlns:nsSong=\"http://song\">
#   <nsBand:band genre="Punk">
#     <nsBand:name>Nofx</nsBand:name>
#   </nsBand:band>
#   <nsSong:song>
#     <nsSong:name>The Brews</nsSong:name>
#   </nsSong:song>
#   <band xmlns=\"http://test.org/band\">
#     <name>El Grupo</name>
#   </band>
# </label>}
#     )
#   end

#   it do
#     NamespaceLabelRepresenter.new(label = Label.new(band, song)).from_xml(
# %{<label xmlns:nsBand="http://test.org/band" xmlns:nsSong=\"http://song\">
#   <nsBand:band>
#     <nsBand:name>Nofx!!!</nsBand:name>
#   </nsBand:band>
#   <nsSong:song>
#     <nsSong:name>Longest Line</nsSong:name>
#   </nsSong:song>
# </label>}
#     )

#     label.song.name.must_equal "Longest Line"
#     label.band.name.must_equal "Nofx!!!"
#   end
# end
