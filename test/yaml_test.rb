require 'test_helper'
require 'representable/yaml'

class YamlTest < MiniTest::Spec
  def self.yaml_representer(&block)
    Module.new do
      include Representable::YAML
      instance_exec &block
    end
  end

  def yaml_representer(&block)
    self.class.yaml_representer(&block)
  end


  describe "property" do
    let (:yaml) { yaml_representer do property :best_song end }

    let (:album) { Album.new.tap do |album|
      album.best_song = "Liar"
    end }

    describe "#to_yaml" do
      it "renders plain property" do
        album.extend(yaml).to_yaml.must_equal(
"---
best_song: Liar
")
      end

      it "always renders values into strings" do
        Album.new.tap { |a| a.best_song = 8675309 }.extend(yaml).to_yaml.must_equal(
"---
best_song: 8675309
"
)
      end
    end


    describe "#from_yaml" do
      it "parses plain property" do
        album.extend(yaml).from_yaml(
"---
best_song: This Song Is Recycled
").best_song.must_equal "This Song Is Recycled"
      end
    end


    describe "with :class and :extend" do
      yaml_song = yaml_representer do property :name end
      let (:yaml_album) { Module.new do
        include Representable::YAML
        property :best_song, :extend => yaml_song, :class => Song
      end }

      let (:album) { Album.new.tap do |album|
        album.best_song = Song.new("Liar")
      end }


      describe "#to_yaml" do
        it "renders embedded typed property" do
          album.extend(yaml_album).to_yaml.must_equal "---
best_song:
  name: Liar
"
        end
      end

      describe "#from_yaml" do
        it "parses embedded typed property" do
          album.extend(yaml_album).from_yaml("---
best_song:
  name: Go With Me
").must_equal Album.new(nil,Song.new("Go With Me"))
        end
      end
    end

    

  end


  describe "collection" do
    let (:yaml) { yaml_representer do collection :songs end }

    let (:album) { Album.new.tap do |album|
      album.songs = ["Jackhammer", "Terrible Man"]
    end }


    describe "#to_yaml" do
      it "renders a block style list per default" do
        album.extend(yaml).to_yaml.must_equal "---
songs:
- Jackhammer
- Terrible Man
"

      end

      it "renders a flow style list when :style => :flow set" do
        yaml = yaml_representer { collection :songs, :style => :flow }
        album.extend(yaml).to_yaml.must_equal "---
songs: [Jackhammer, Terrible Man]
"
      end
    end

    describe "with :class and :extend" do
      yaml_song = yaml_representer do 
        property :name
        property :track
      end
      let (:yaml_album) { Module.new do
        include Representable::YAML
        collection :songs, :extend => yaml_song
      end }

      let (:album) { Album.new.tap do |album|
        album.songs = [Song.new("Liar", 1), Song.new("What I Know", 2)]
      end }


      describe "#to_yaml" do
        it "renders collection of typed property" do
          album.extend(yaml_album).to_yaml.must_equal "---
songs:
- name: Liar
  track: 1
- name: What I Know
  track: 2
"
        end
      end
    end
  end
end