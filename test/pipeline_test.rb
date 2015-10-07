require "test_helper"

class PipelineTest < MiniTest::Spec
  Song   = Struct.new(:title, :artist)
  Artist = Struct.new(:name)
  Album  = Struct.new(:ratings, :artists)

  R = Representable
  P = R::Pipeline

  Getter        = ->(input, options) { "Yo" }
  StopOnNil     = ->(input, options) { input }
  SkipRender    = ->(input, *) { input == "Yo" ? input : P::Stop }

  Prepare       = ->(input, options) { "Prepare(#{input})" }
  Deserialize   = ->(input, options) { "Deserialize(#{input}, #{options[:fragment]})" }

  SkipParse     = ->(input, options) { input }
  CreateObject  = ->(input, options) { OpenStruct.new }


  Setter        = ->(input, options) { "Setter(#{input})" }

  AssignFragment = ->(input, options) { options[:fragment] = input }

  it "linear" do
    P[SkipParse, Setter].("doc", {fragment: 1}).must_equal "Setter(doc)"


    # parse style.
    P[AssignFragment, SkipParse, CreateObject, Prepare].("Bla", {}).must_equal "Prepare(#<OpenStruct>)"


    # render style.
    P[Getter, StopOnNil, SkipRender, Prepare, Setter].(nil, {}).
      must_equal "Setter(Prepare(Yo))"

    # pipeline = Representable::Pipeline[SkipParse  , SetResult, ModifyResult]
    # pipeline.(fragment: "yo!").must_equal "modified object from yo!"
  end

  Stopping      = ->(input, options) { return P::Stop if options[:fragment] == "stop!"; input }


  it "stopping" do


    pipeline = Representable::Pipeline[SkipParse, Stopping, Prepare]
    pipeline.(nil, fragment: "oy!").must_equal "Prepare()"
    pipeline.(nil, fragment: "stop!").must_equal Representable::Pipeline::Stop
  end

  describe "Collect" do
  #   let(:pipeline) { Representable::Pipeline[Representable::Collect[SetResult, Stopping, ModifyResult]] }

  #   it { pipeline.(fragment: ["yo!", "oy!"]).must_equal ["modified object from yo!", "modified object from oy!"] }
  #   it { pipeline.(fragment: ["yo!", "stop!", "oy!"]).must_equal ["modified object from yo!", "modified object from oy!"] }
  end




  ######### scalar property

  let (:title) {
    dfn = R::Definition.new(:title)

    R::Hash::Binding.new(dfn, "parent decorator").tap do |bin|
      bin.update!(Song.new("Lime Green"), {}) # FIXME: how do i do that again in representable?
    end
  }

  it "rendering scalar property" do
    doc = {}
    P[
      R::Getter,
      R::StopOnSkipable,
      R::WriteFragment
    ].(nil, {binding: title, doc: doc}).must_equal "Lime Green"

    doc.must_equal({"title"=>"Lime Green"})
  end

  it "parsing scalar property" do
    P[
      R::ReadFragment,
      R::StopOnNotFound,
      R::OverwriteOnNil,
      # R::SkipParse,
      R::Setter,
    ].extend(P::Debug).(doc={"title"=>"Eruption"}, {binding: title, doc: doc}).must_equal "Eruption"
    title.represented.title.must_equal "Eruption"
  end



  module ArtistRepresenter
    include Representable::Hash
    property :name
  end

  let (:artist) {
    dfn = R::Definition.new(:artist, extend: ArtistRepresenter, class: Artist)

    R::Hash::Binding.new(dfn, "parent decorator").tap do |bin|
      bin.update!(Song.new("Lime Green", Artist.new("Diesel Boy")), {}) # FIXME: how do i do that again in representable?
    end
  }

  it "rendering typed property" do
    doc = {}
    P[
      R::Getter,
      R::StopOnSkipable,
      R::StopOnNil,
      R::SkipRender,
      R::Prepare,
      R::Serialize,
      R::WriteFragment
    ].extend(P::Debug).(nil, {binding: artist, doc: doc}).must_equal({"name" => "Diesel Boy"})

    doc.must_equal({"artist"=>{"name"=>"Diesel Boy"}})
  end

  it "parsing typed property" do
    P[
      R::ReadFragment,
      R::StopOnNotFound,
      R::OverwriteOnNil,
      # R::SkipParse,
      R::CreateObject,
      R::Prepare,
      R::Deserialize,
      R::Setter,
    ].extend(P::Debug).(doc={"artist"=>{"name"=>"Doobie Brothers"}}, {binding: artist, doc: doc}).must_equal model=Artist.new("Doobie Brothers")
    artist.represented.artist.must_equal model
  end


  ######### collection :ratings

  let (:ratings) {
    dfn = R::Definition.new(:ratings, collection: true)

    R::Hash::Binding::Collection.new(dfn, "parent decorator").tap do |bin|
      bin.update!(Album.new([1,2,3]), {}) # FIXME: how do i do that again in representable?
    end
  }
  it "render scalar collection" do
    doc = {}
    P[
      R::Getter,
      R::StopOnSkipable,
      R::Collect[
        R::SkipRender,
      ],
      R::WriteFragment
    ].extend(P::Debug).(nil, {binding: ratings, doc: doc}).must_equal([1,2,3])

    doc.must_equal({"ratings"=>[1,2,3]})
  end

######### collection :songs, extend: SongRepresenter
  let (:artists) {
    dfn = R::Definition.new(:artists, collection: true, extend: ArtistRepresenter, class: Artist)

    R::Hash::Binding::Collection.new(dfn, "parent decorator").tap do |bin|
      bin.update!(Album.new(nil, [Artist.new("Diesel Boy"), Artist.new("Van Halen")]), {}) # FIXME: how do i do that again in representable?
    end
  }
  it "render typed collection" do
    doc = {}
    P[
      R::Getter,
      R::StopOnSkipable,
      R::Collect[
        R::SkipRender,
        R::Prepare,
        R::Serialize,
      ],
      R::WriteFragment
    ].extend(P::Debug).(nil, {binding: artists, doc: doc}).must_equal([{"name"=>"Diesel Boy"}, {"name"=>"Van Halen"}])

    doc.must_equal({"artists"=>[{"name"=>"Diesel Boy"}, {"name"=>"Van Halen"}]})
  end


  it "parse typed collection" do
    doc = {"artists"=>[{"name"=>"Diesel Boy"}, {"name"=>"Van Halen"}]}
    P[
      R::ReadFragment,
      R::StopOnNotFound,
      R::OverwriteOnNil,
      # R::SkipParse,
      R::Collect[
        R::SkipRender,
        R::CreateObject,
        R::Prepare,
        R::Deserialize,
      ],
      R::Setter,
    ].extend(P::Debug).(doc, {binding: artists, doc: doc}).must_equal([Artist.new("Diesel Boy"), Artist.new("Van Halen")])

    artists.represented.artists.must_equal([Artist.new("Diesel Boy"), Artist.new("Van Halen")])
  end

  # TODO: test with arrays, too, not "only" Pipeline instances.
  describe "#Insert Pipeline[], Function, replace: OldFunction" do
    let (:pipeline) { P[R::Getter, R::StopOnSkipable, R::StopOnNil] }

    it "replaces if exists" do
      # pipeline.insert!(R::Default, replace: R::StopOnSkipable)
      P::Insert.(pipeline, R::Default, replace: R::StopOnSkipable).must_equal P[R::Getter, R::Default, R::StopOnNil]
      pipeline.must_equal P[R::Getter, R::StopOnSkipable, R::StopOnNil]
    end

    it "replaces Function instance" do
      pipeline = P[R::Prepare, R::StopOnSkipable, R::StopOnNil]
      P::Insert.(pipeline, R::Default, replace: R::Prepare).must_equal P[R::Default, R::StopOnSkipable, R::StopOnNil]
      pipeline.must_equal P[R::Prepare, R::StopOnSkipable, R::StopOnNil]
    end

    it "does not replace when not existing" do
      P::Insert.(pipeline, R::Default, replace: R::Prepare)
      pipeline.must_equal P[R::Getter, R::StopOnSkipable, R::StopOnNil]
    end
  end
end