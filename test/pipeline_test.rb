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
    Reverse = ->(input, options) { input.reverse }
    Add = ->(input, options) { "#{input}+" }
    let(:pipeline) { R::Collect[Reverse, Add] }

    it { pipeline.(["yo!", "oy!"], {}).must_equal ["!oy+", "!yo+"] }

    describe "Pipeline with Collect" do
      let(:pipeline) { P[Reverse, R::Collect[Reverse, Add]] }
      it { pipeline.(["yo!", "oy!"], {}).must_equal ["!yo+", "!oy+"] }
    end
  end




  ######### scalar property

  let (:title) {
    dfn = R::Definition.new(:title)

    R::Hash::Binding.new(dfn, "parent decorator")
  }

  it "rendering scalar property" do
    doc = {}
    P[
      R::Get,
      R::StopOnSkipable,
      R::AssignName,
      R::WriteFragment
    ].(nil, {represented: Song.new("Lime Green"), binding: title, doc: doc}).must_equal "Lime Green"

    doc.must_equal({"title"=>"Lime Green"})
  end

  it "parsing scalar property" do
    P[
      R::AssignName,
      R::ReadFragment,
      R::StopOnNotFound,
      R::OverwriteOnNil,
      # R::SkipParse,
      R::Set,
    ].extend(P::Debug).(doc={"title"=>"Eruption"}, {represented: song=Song.new("Lime Green"), binding: title, doc: doc}).must_equal "Eruption"
    song.title.must_equal "Eruption"
  end



  module ArtistRepresenter
    include Representable::Hash
    property :name
  end

  let (:artist) {
    dfn = R::Definition.new(:artist, extend: ArtistRepresenter, class: Artist)

    R::Hash::Binding.new(dfn, "parent decorator")
  }

  let (:song_model) { Song.new("Lime Green", Artist.new("Diesel Boy")) }

  it "rendering typed property" do
    doc = {}
    P[
      R::Get,
      R::StopOnSkipable,
      R::StopOnNil,
      R::SkipRender,
      R::Decorate,
      R::Serialize,
      R::AssignName,
      R::WriteFragment
    ].extend(P::Debug).(nil, {represented: song_model, binding: artist, doc: doc, user_options: {}}).must_equal({"name" => "Diesel Boy"})

    doc.must_equal({"artist"=>{"name"=>"Diesel Boy"}})
  end

  it "parsing typed property" do
    P[
      R::AssignName,
      R::ReadFragment,
      R::StopOnNotFound,
      R::OverwriteOnNil,
      # R::SkipParse,
      R::CreateObject,
      R::Decorate,
      R::Deserialize,
      R::Set,
    ].extend(P::Debug).(doc={"artist"=>{"name"=>"Doobie Brothers"}}, {represented: song_model, binding: artist, doc: doc, user_options: {}}).must_equal model=Artist.new("Doobie Brothers")
    song_model.artist.must_equal model
  end


  ######### collection :ratings

  let (:ratings) {
    dfn = R::Definition.new(:ratings, collection: true)

    R::Hash::Binding::Collection.new(dfn, "parent decorator")
  }
  it "render scalar collection" do
    doc = {}
    P[
      R::Get,
      R::StopOnSkipable,
      R::Collect[
        R::SkipRender,
      ],
      R::AssignName,
      R::WriteFragment
    ].extend(P::Debug).(nil, {represented: Album.new([1,2,3]), binding: ratings, doc: doc}).must_equal([1,2,3])

    doc.must_equal({"ratings"=>[1,2,3]})
  end

######### collection :songs, extend: SongRepresenter
  let (:artists) {
    dfn = R::Definition.new(:artists, collection: true, extend: ArtistRepresenter, class: Artist)

    R::Hash::Binding::Collection.new(dfn, "parent decorator")
  }
  it "render typed collection" do
    doc = {}
    P[
      R::Get,
      R::StopOnSkipable,
      R::Collect[
        R::SkipRender,
        R::Decorate,
        R::Serialize,
      ],
      R::AssignName,
      R::WriteFragment
    ].extend(P::Debug).(nil, {represented: Album.new(nil, [Artist.new("Diesel Boy"), Artist.new("Van Halen")]), binding: artists, doc: doc, user_options: {}}).must_equal([{"name"=>"Diesel Boy"}, {"name"=>"Van Halen"}])

    doc.must_equal({"artists"=>[{"name"=>"Diesel Boy"}, {"name"=>"Van Halen"}]})
  end

let (:album_model) { Album.new(nil, [Artist.new("Diesel Boy"), Artist.new("Van Halen")]) }

  it "parse typed collection" do
    doc = {"artists"=>[{"name"=>"Diesel Boy"}, {"name"=>"Van Halen"}]}
    P[
      R::AssignName,
      R::ReadFragment,
      R::StopOnNotFound,
      R::OverwriteOnNil,
      # R::SkipParse,
      R::Collect[
        R::SkipRender,
        R::CreateObject,
        R::Decorate,
        R::Deserialize,
      ],
      R::Set,
    ].extend(P::Debug).(doc, {represented: album_model, binding: artists, doc: doc, user_options: {}}).must_equal([Artist.new("Diesel Boy"), Artist.new("Van Halen")])

    album_model.artists.must_equal([Artist.new("Diesel Boy"), Artist.new("Van Halen")])
  end

  # TODO: test with arrays, too, not "only" Pipeline instances.
  describe "#Insert Pipeline[], Function, replace: OldFunction" do
    let (:pipeline) { P[R::Get, R::StopOnSkipable, R::StopOnNil] }

    it "returns Pipeline instance when passing in Pipeline instance" do
      P::Insert.(pipeline, R::Default, replace: R::StopOnSkipable).must_be_instance_of(R::Pipeline)
    end

    it "replaces if exists" do
      # pipeline.insert!(R::Default, replace: R::StopOnSkipable)
      P::Insert.(pipeline, R::Default, replace: R::StopOnSkipable).must_equal P[R::Get, R::Default, R::StopOnNil]
      pipeline.must_equal P[R::Get, R::StopOnSkipable, R::StopOnNil]
    end

    it "replaces Function instance" do
      pipeline = P[R::Prepare, R::StopOnSkipable, R::StopOnNil]
      P::Insert.(pipeline, R::Default, replace: R::Prepare).must_equal P[R::Default, R::StopOnSkipable, R::StopOnNil]
      pipeline.must_equal P[R::Prepare, R::StopOnSkipable, R::StopOnNil]
    end

    it "does not replace when not existing" do
      P::Insert.(pipeline, R::Default, replace: R::Prepare)
      pipeline.must_equal P[R::Get, R::StopOnSkipable, R::StopOnNil]
    end

    it "applies on nested Collect" do
      pipeline = P[R::Get, R::Collect[R::Get, R::StopOnSkipable], R::StopOnNil]

      P::Insert.(pipeline, R::Default, replace: R::StopOnSkipable).extend(P::Debug).inspect.must_equal "Pipeline[Get, Collect[Get, Default], StopOnNil]"
      pipeline.must_equal P[R::Get, R::Collect[R::Get, R::StopOnSkipable], R::StopOnNil]


      P::Insert.(pipeline, R::Default, replace: R::StopOnNil).extend(P::Debug).inspect.must_equal "Pipeline[Get, Collect[Get, StopOnSkipable], Default]"
    end
  end

  describe "Insert delete: true" do
    let(:pipeline) { P[R::Get, R::Collect[R::Get, R::StopOnSkipable], R::StopOnNil] }

    it do
      P::Insert.(pipeline, R::Get, delete: true).extend(P::Debug).inspect.must_equal "Pipeline[Collect[Get, StopOnSkipable], StopOnNil]"
      pipeline.extend(P::Debug).inspect.must_equal "Pipeline[Get, Collect[Get, StopOnSkipable], StopOnNil]"
    end
  end
end