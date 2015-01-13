require "test_helper"
require "representable/object"

class ObjectTest < MiniTest::Spec
  Song  = Struct.new(:title, :album)
  Album = Struct.new(:name, :songs)

  representer!(module: Representable::Object) do
    property :title

    property :album, instance: lambda { |fragment, *| fragment } do
      property :name

      collection :songs, instance: lambda { |fragment, *|fragment } do
        property :title
      end
    end
    # TODO: collection
  end

  let (:source) { Song.new("The King Is Dead", Album.new("Ruiner", [Song.new("In Vino Veritas II")])) }
  let (:target) { Song.new }

  it do
    representer.prepare(target).from_object(source)

    target.title.must_equal "The King Is Dead"
    target.album.name.must_equal "Ruiner"
    target.album.songs[0].title.must_equal "In Vino Veritas II"
  end
end