require "test_helper"

class DefaultTest < MiniTest::Spec
  Song = Struct.new(:id, :title)

  representer! do
    property :id
    property :title, default: "Huber Breeze" #->(options) { options[:default] }
  end

  it { Song.new.extend(representer).from_hash({}).must_equal Song.new(nil, "Huber Breeze") }
  # default doesn't apply when empty string.
  it { Song.new.extend(representer).from_hash({"title"=>""}).must_equal Song.new(nil, "") }
  it { Song.new.extend(representer).from_hash({"title"=>nil}).must_equal Song.new(nil, nil) }
  it { Song.new.extend(representer).from_hash({"title"=>"Blindfold"}).must_equal Song.new(nil, "Blindfold") }
end