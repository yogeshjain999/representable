require 'test_helper'

class FilterPipelineTest < MiniTest::Spec
  let (:block1) { lambda { |options| "1: #{options[:result]}" } }
  let (:block2) { lambda { |options| "2: #{options[:result]}" } }

  subject { Representable::Pipeline[block1, block2] }

  it { subject.call(result: "Horowitz").must_equal "2: 1: Horowitz" }
end


class FilterTest < MiniTest::Spec
  representer! do
    property :title
    property :track,
      :parse_filter  => lambda { |options| "#{options[:result].downcase},#{options[:doc]}" },
      :render_filter => lambda { |val, doc, options| "#{val.upcase},#{doc},#{options}" }
  end

  # gets doc and options.
  it {
    song = OpenStruct.new.extend(representer).from_hash("title" => "VULCAN EARS", "track" => "Nine")
    song.title.must_equal "VULCAN EARS"
    song.track.must_equal "nine,{\"title\"=>\"VULCAN EARS\", \"track\"=>\"Nine\"}"
  }

  it { OpenStruct.new("title" => "vulcan ears", "track" => "Nine").extend(representer).to_hash.must_equal( {"title"=>"vulcan ears", "track"=>"NINE,{\"title\"=>\"vulcan ears\"},{}"}) }


  describe "#parse_filter" do
    representer! do
      property :track,
        :parse_filter => [
          lambda { |options| "#{options[:result]}-1" },
          lambda { |options| "#{options[:result]}-2" }],
        :render_filter => [
          lambda { |val, doc, options| "#{val}-1" },
          lambda { |val, doc, options| "#{val}-2" }]
    end

    # order matters.
    it { OpenStruct.new.extend(representer).from_hash("track" => "Nine").track.must_equal "Nine-1-2" }
    it { OpenStruct.new("track" => "Nine").extend(representer).to_hash.must_equal({"track"=>"Nine-1-2"}) }
  end
end


class RenderFilterTest < MiniTest::Spec
  representer! do
    property :track, :render_filter => [lambda { |val, doc, options| "#{val}-1" } ]
    property :track, :render_filter => [lambda { |val, doc, options| "#{val}-2" } ], :inherit => true
  end

  it { OpenStruct.new("track" => "Nine").extend(representer).to_hash.must_equal({"track"=>"Nine-1-2"}) }
end