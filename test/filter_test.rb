require 'test_helper'

class FilterPipelineTest < MiniTest::Spec
  let (:block1) { lambda { |value, *| "1: #{value}" } }
  let (:block2) { lambda { |value, *| "2: #{value}" } }

  subject { Representable::Pipeline[block1, block2] }

  it { subject.call(Object, "Horowitz").must_equal "2: 1: Horowitz" }
end


class ParseFilterTest < MiniTest::Spec
  representer! do
    property :title
    property :track, :parse_filter => lambda { |val, options| val.downcase }
  end

  it {
    song = OpenStruct.new.extend(representer).from_hash("title" => "VULCAN EARS", "track" => "Nine")
    song.title.must_equal "VULCAN EARS"
    song.track.must_equal "nine"
  }
end

class RenderFilterTest < MiniTest::Spec
  representer! do
    property :title
    property :track, :render_filter => lambda { |val, options| val.downcase }
  end

  it { OpenStruct.new("title" => "VULCAN EARS", "track" => "Nine").extend(representer).to_hash.must_equal({"title"=>"VULCAN EARS", "track"=>"nine"}) }
end