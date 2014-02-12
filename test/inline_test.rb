require 'test_helper'

class InlineTest < MiniTest::Spec
  let (:song)    { Song.new("Alive") }
  let (:request) { representer.prepare(OpenStruct.new(:song => song)) }

  {
    :hash => [Representable::Hash, {"song"=>{"name"=>"Alive"}}, {"song"=>{"name"=>"You've Taken Everything"}}],
    :json => [Representable::JSON, "{\"song\":{\"name\":\"Alive\"}}", "{\"song\":{\"name\":\"You've Taken Everything\"}}"],
    :xml  => [Representable::XML, "<open_struct>\n  <song>\n    <name>Alive</name>\n  </song>\n</open_struct>", "<open_struct><song><name>You've Taken Everything</name></song>/open_struct>"],
    :yaml => [Representable::YAML, "---\nsong:\n  name: Alive\n", "---\nsong:\n  name: You've Taken Everything\n"],
  }.each do |format, cfg|
    mod, output, input = cfg

    describe "[#{format}] with :class" do
      representer!(mod) do
        property :song, :class => Song do
          property :name
        end
      end

      it { request.send("to_#{format}").must_equal output }
      it { request.send("from_#{format}", input).song.name.must_equal "You've Taken Everything"}
    end
  end

  {
    :hash => [Representable::Hash, {"songs"=>[{"name"=>"Alive"}]}, {"songs"=>[{"name"=>"You've Taken Everything"}]}],
    :json => [Representable::JSON, "{\"songs\":[{\"name\":\"Alive\"}]}", "{\"songs\":[{\"name\":\"You've Taken Everything\"}]}"],
    :xml  => [Representable::XML, "<open_struct>\n  <song>\n    <name>Alive</name>\n  </song>\n</open_struct>", "<open_struct><song><name>You've Taken Everything</name></song></open_struct>", { :from => :song }],
    :yaml => [Representable::YAML, "---\nsongs:\n- name: Alive\n", "---\nsongs:\n- name: You've Taken Everything\n"],
  }.each do |format, cfg|
    mod, output, input, collection_options = cfg
    collection_options ||= {}

    describe "[#{format}] collection with :class" do
      let (:request) { representer.prepare(OpenStruct.new(:songs => [song])) }

      representer!(mod) do
        collection :songs, collection_options.merge(:class => Song) do
          property :name
        end
      end

      it { request.send("to_#{format}").must_equal output }
      it { request.send("from_#{format}", input).songs.first.name.must_equal "You've Taken Everything"}
    end
  end

  describe "without :class" do
    representer! do
      property :song do
        property :name
      end
    end

    it { request.to_hash.must_equal({"song"=>{"name"=>"Alive"}}) }
  end

  describe "decorator" do
    let (:representer) do
      Class.new(Representable::Decorator) do
        include Representable::Hash

        property :song, :class => Song do
          property :name
        end

        self
      end
    end

    it { request.to_hash.must_equal({"song"=>{"name"=>"Alive"}}) }
    it { request.from_hash({"song"=>{"name"=>"You've Taken Everything"}}).song.name.must_equal "You've Taken Everything"}

    it "uses an inline decorator" do
      request.to_hash
      song.wont_be_kind_of Representable
    end
  end

  # TODO: should be in extend:/decorator: test.
  # FIXME: this tests :getter{represented}+:extend - represented gets extended twice and the inline decorator overrides original config.
  # for_formats(
  #   :hash => [Representable::Hash, {"album" => {"artist" => {"label"=>"Epitaph"}}}],
  #   # :xml  => [Representable::XML, "<open_struct></open_struct>"],
  #   #:yaml => [Representable::YAML, "---\nlabel:\n  label: Epitaph\n  owner: Brett Gurewitz\n"]
  # ) do |format, mod, output, input|

  #   module ArtistRepresenter
  #     include Representable::JSON
  #     property :label
  #   end

  #   describe ":getter with inline representer" do
  #     let (:format) { format }

  #     representer!(:module => mod) do
  #       self.representation_wrap = :album

  #       property :artist, :getter => lambda { |args| represented }, :extend => ArtistRepresenter
  #     end

  #     let (:album) { OpenStruct.new(:label => "Epitaph").extend(representer) }

  #     it "renders nested Album-properties in separate section" do
  #       render(album).must_equal_document output
  #     end
  #   end
  # end
  for_formats(
    :hash => [Representable::Hash, {"album" => {"artist" => {"label"=>"Epitaph"}}}],
    # :xml  => [Representable::XML, "<open_struct></open_struct>"],
    #:yaml => [Representable::YAML, "---\nlabel:\n  label: Epitaph\n  owner: Brett Gurewitz\n"]
  ) do |format, mod, output, input|

    class ArtistRepresenter < Representable::Decorator
      include Representable::JSON
      property :label
    end

    describe ":getter with inline representer" do
      let (:format) { format }

      representer!(:module => mod) do
        self.representation_wrap = "album"

        property :artist, :getter => lambda { |args| represented }, :decorator => ArtistRepresenter
      end

      let (:album) { OpenStruct.new(:label => "Epitaph").extend(representer) }

      it "renders nested Album-properties in separate section" do
        render(album).must_equal_document output
      end
    end
  end
end
