require 'test_helper'

class ForCollectionTest < MiniTest::Spec
  module SongRepresenter
    include Representable::JSON

    property :name
  end

  let (:songs) { [Song.new("Days Go By"), Song.new("Can't Take Them All")] }
  let (:json)  { "[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]" }


  # Module.for_collection
  # Decorator.for_collection
  for_formats(
    :hash => [Representable::Hash, out=[{"name" => "Days Go By"}, {"name"=>"Can't Take Them All"}], out],
    :json => [Representable::JSON, out="[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]", out],
    # :xml  => [Representable::XML,  out="<a><song></song><song></song></a>", out]
  ) do |format, mod, output, input|

    describe "Module::for_collection [#{format}]" do
      let (:format) { format }

      let (:representer) {
        Module.new do
          include mod
          property :name#, :as => :title

          collection_representer :class => Song

          # self.representation_wrap = :songs if format == :xml
        end
      }

      it { render(songs.extend(representer.for_collection)).must_equal_document output }
      it { render(representer.for_collection.prepare(songs)).must_equal_document output }
      # parsing needs the class set, at least
      it { parse([].extend(representer.for_collection), input).must_equal songs }
    end

    describe "Module::for_collection without configuration [#{format}]" do
      let (:format) { format }

      let (:representer) {
        Module.new do
          include mod
          property :name
        end
      }

      # rendering works out of the box, no config necessary
      it { render(songs.extend(representer.for_collection)).must_equal_document output }
    end


    describe "Decorator::for_collection [#{format}]" do
      let (:format) { format }
      let (:representer) {
        Class.new(Representable::Decorator) do
          include mod
          property :name

          collection_representer :class => Song
        end
      }

      it { render(representer.for_collection.new(songs)).must_equal_document output }
      it { parse(representer.for_collection.new([]), input).must_equal songs }
    end
  end

  # with module including module
end


class ImplicitCollectionTest < MiniTest::Spec
  let (:songs) { [song, Song.new("Can't Take Them All")] }
  let (:song) { Song.new("Days Go By") }

  for_formats(
    :hash => [Representable::Hash, out=[{"name" => "Days Go By"}, {"name"=>"Can't Take Them All"}], out],
    :json => [Representable::JSON, out="[{\"name\":\"Days Go By\"},{\"name\":\"Can't Take Them All\"}]", out],
    # :xml  => [Representable::XML,  out="<a><song></song><song></song></a>", out]
  ) do |format, mod, output, input|

    # collection is automatically detected.
    describe "Module#to_/from_#{format}" do
      let (:format) { format }

      let (:representer) {
        Module.new do
          include mod
          extend Representable::Represent
          property :name

          collection_representer :class => Song # TODOOOOOOOOOOOO: test without Song and fix THIS FUCKINGNoMethodError: undefined method `name=' for {"name"=>"Days Go By"}:Hash ERROR!!!!!!!!!!!!!!!
        end
      }

      it { render(representer.represent(songs)).must_equal_document output }
      it { parse(representer.represent([]), input).must_equal songs }
    end


    # describe "Decorator::for_collection [#{format}]" do
    #   let (:format) { format }
    #   let (:representer) {
    #     Class.new(Representable::Decorator) do
    #       include mod
    #       property :name

    #       collection_representer :class => Song
    #     end
    #   }

    #   it { render(representer.for_collection.new(songs)).must_equal_document output }
    #   it { parse(representer.for_collection.new([]), input).must_equal songs }
    # end
  end


  for_formats(
    :hash => [Representable::Hash, out={"name" => "Days Go By"}, out],
    :json => [Representable::JSON, out="{\"name\":\"Days Go By\"}", out],
    # :xml  => [Representable::XML,  out="<a><song></song><song></song></a>", out]
  ) do |format, mod, output, input|

    # singular is automatically detected.
    describe "Module#to_/from_#{format}" do
      let (:format) { format }

      let (:representer) {
        Module.new do
          include mod
          extend Representable::Represent
          property :name

          collection_representer :class => Song
        end
      }

      it { render(representer.represent(song)).must_equal_document output }
      it { parse(representer.represent(Song.new), input).must_equal song }
    end


    # describe "Decorator::for_collection [#{format}]" do
    #   let (:format) { format }
    #   let (:representer) {
    #     Class.new(Representable::Decorator) do
    #       include mod
    #       property :name

    #       collection_representer :class => Song
    #     end
    #   }

    #   it { render(representer.for_collection.new(songs)).must_equal_document output }
    #   it { parse(representer.for_collection.new([]), input).must_equal songs }
    # end
  end
end