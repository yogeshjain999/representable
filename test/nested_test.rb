require 'test_helper'

class NestedTest < MiniTest::Spec
	Album = Struct.new(:label, :owner)

	for_formats(
    :hash => [Representable::Hash, hsh={"label" => {"label"=>"Epitaph", "owner"=>"Brett Gurewitz"}}, hsh],
    # :xml  => [Representable::XML, "<open_struct></open_struct>"],
    :yaml => [Representable::YAML, "---\nlabel:\n  label: Epitaph\n  owner: Brett Gurewitz\n"]
  ) do |format, mod, output, input|

    describe "::nested with inline representer" do
      let (:format) { format }

      representer!(:module => mod) do
        nested :label do
        	property :label
        	property :owner

        	# self.representation_wrap = nil if format == :xml
        end


        self.representation_wrap = :album if format == :xml
      end

      let (:album) { Album.new("Epitaph", "Brett Gurewitz").extend(representer) }

      it "renders nested Album-properties in separate section" do
        render(album).must_equal_document output
      end

      it "parses nested properties to Album instance" do
      	album = parse(Album.new.extend(representer), output)
      	album.label.must_equal "Epitaph"
      	album.owner.must_equal "Brett Gurewitz"
      end
    end

    describe "::nested with extend:" do
      let (:format) { format }

      module LabelRepresenter
      	include Representable::JSON
      	property :label
        property :owner
      end

      representer!(:module => mod) do
        nested :label, :extend => LabelRepresenter

        self.representation_wrap = :album if format == :xml
      end

      let (:album) { Album.new("Epitaph", "Brett Gurewitz").extend(representer) }

      # TODO: shared example with above.
      it "renders nested Album-properties in separate section" do
        render(album).must_equal_document output
      end

      it "parses nested properties to Album instance" do
      	album = parse(Album.new.extend(representer), output)
      	album.label.must_equal "Epitaph"
      	album.owner.must_equal "Brett Gurewitz"
      end
    end
  end
end