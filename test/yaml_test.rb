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
        album.extend(yaml).to_yaml.must_equal "---
- best_song: Liar
"
      end

    end

    describe "with :class and :extend" do
      yaml_song = yaml_representer do property :name end
      let (:yaml_album) { Module.new do
        include Representable::YAML
        property :best_song, :extend => yaml_song
      end }

      let (:album) { Album.new.tap do |album|
        album.best_song = Song.new("Liar")
      end }


      describe "#to_yaml" do
        it "renders embedded typed property" do
          album.extend(yaml_album).to_yaml.must_equal "---
- best_song: Liar
"
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
- songs:
  - Jackhammer
  - Terrible Man
"

      end

      it "renders a flow style list when :style => :flow set" do
        yaml = yaml_representer { collection :songs, :style => :flow }
        album.extend(yaml).to_yaml.must_equal "---
- songs: [Jackhammer, Terrible Man]
"
      end
    end
  end
end