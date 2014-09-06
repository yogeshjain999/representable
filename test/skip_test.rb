require 'test_helper'

class SkipTest < MiniTest::Spec
  representer! do
    property :title
    property :band,
      skip_parse: lambda { |fragment, opts| opts[:skip?] and fragment["name"].nil? }, class: OpenStruct do
        property :name
    end

    collection :airplays,
      skip_parse: lambda { |fragment, opts| puts fragment.inspect; opts[:skip?] and fragment["station"].nil? }, class: OpenStruct do
        property :station
    end
  end

  let (:song) { OpenStruct.new.extend(representer) }

  # do parse.
  it { song.from_hash({"band" => {"name" => "Mute 98"}}, skip?: true).band.name.must_equal "Mute 98" }
  it { song.from_hash({"airplays" => [{"station" => "JJJ"}]}, skip?: true).airplays[0].station.must_equal "JJJ" }

  # skip parsing.
  it { song.from_hash({"band" => {}}, skip?: true).band.must_equal nil }
end