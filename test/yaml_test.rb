require 'test_helper'
require 'representable/yaml'

class YamlTest < MiniTest::Spec
  describe "collection" do
    let (:yaml) { Module.new do
      include Representable::YAML
      collection :songs
    end }

    let (:album) { Album.new.tap do |album|
      album.songs = ["Jackhammer", "Terrible Man"]
    end }


    describe "#to_yaml" do
      it "renders a standard list" do
        album.extend(yaml).to_yaml.must_equal "---
- songs:
  - Jackhammer
  - Terrible Man
"

      end
    end
  end
end