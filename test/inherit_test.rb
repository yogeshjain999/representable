require 'test_helper'

class InheritTest < MiniTest::Spec
  module SongRepresenter # it's important to have a global module so we can test if stuff gets overridden in the original module.
    include Representable::Hash
    property :name, :as => :title do
      property :string, :as => :str
    end

    property :track, :as => :no
  end

  let (:song) { Song.new(Struct.new(:string).new("Roxanne"), 1) }

  describe ":inherit plain property" do
    representer! do
      include SongRepresenter

      property :track, :inherit => true, :getter => lambda { |*| "n/a" }
    end

    it { SongRepresenter.prepare(song).to_hash.must_equal({"title"=>{"str"=>"Roxanne"}, "no"=>1}) }
    it { representer.prepare(song).to_hash.must_equal({"title"=>{"str"=>"Roxanne"}, "no"=>"n/a"}) } # as: inherited.
  end

  describe ":inherit with empty inline representer" do
    representer! do
      include SongRepresenter

      property :name, :inherit => true do # inherit as: title
        # that doesn't make sense.
      end
    end

    it { SongRepresenter.prepare(Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash.must_equal({"title"=>{"str"=>"Believe It"}, "no"=>1}) }
    it { representer.prepare( Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash.must_equal({"title"=>{"str"=>"Believe It"}, "no"=>1}) }
  end

  describe ":inherit with overriding inline representer" do
    representer! do
      include SongRepresenter

      property :name, :inherit => true do # inherit as: title
        property :string, :as => :s
        property :length
        puts "block exec"
      end
    end

    it { representer.prepare( Song.new(Struct.new(:string, :length).new("Believe It", 10), 1)).to_hash.must_equal({"title"=>{"s"=>"Believe It","length"=>10}, "no"=>1}) }
  end

  describe ":inherit with inline and options" do
    representer! do
      include SongRepresenter

      property :name, :inherit => true, :as => :name do # inherit module, only.
        # that doesn't make sense.
      end
    end

    it { SongRepresenter.prepare(Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash.must_equal({"title"=>{"str"=>"Believe It"}, "no"=>1}) }
    it { representer.prepare( Song.new(Struct.new(:string).new("Believe It"), 1)).to_hash.must_equal({"name"=>{"str"=>"Believe It"}, "no"=>1}) }
  end

end