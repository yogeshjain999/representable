require 'test_helper'

class InheritTest < MiniTest::Spec
  module SongRepresenter
    include Representable::Hash
    property :name, :as => :title
    property :track
  end

  module HitRepresenter
    include Representable::Hash
    include SongRepresenter

    property :title, :inherit => true, :getter => lambda { |*| "Creeping Out Sara" }
  end
  let (:song) { Song.new("Roxanne", 1) }

  it { SongRepresenter.prepare(song).to_hash.must_equal({"title"=>"Roxanne", "track"=>1}) }
  it { HitRepresenter.prepare(song).to_hash.must_equal({"title"=>"Creeping Out Sara", "track"=>1}) } # as: inherited.

end