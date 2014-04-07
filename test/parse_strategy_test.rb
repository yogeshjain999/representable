require 'test_helper'

# parse_strategy: :sync
# parse_strategy: :replace
# parse_strategy: :find_or_instantiate ("expand" since we don't delete existing unmatched in target)


class ParseStrategyTest < BaseTest
  for_formats(
    :hash => [Representable::Hash, {"song"=>{"title"=>"Resist Stance"}}, {"song"=>{"title"=>"Suffer"}}],
    :xml  => [Representable::XML, "<open_struct><song><title>Resist Stance</title></song></open_struct>", "<open_struct><song><title>Suffer</title></song></open_struct>",],
    :yaml => [Representable::YAML, "---\nsong:\n  title: Resist Stance\n", "---\nsong:\n  title: Suffer\n"],
  ) do |format, mod, output, input|

    describe "[#{format}] property with parse_strategy: :sync" do # TODO: introduce :representable option?
      let (:format) { format }

      representer!(:module => mod, :name => :song_representer) do
        property :title
        self.representation_wrap = :song if format == :xml
      end

      representer!(:inject => :song_representer, :module => mod) do
        property :song, :parse_strategy => :sync, :extend => song_representer
      end

      let (:hit) { hit = OpenStruct.new(:song => song).extend(representer) }

      it "calls #to_hash on song instance, nothing else" do
        render(hit).must_equal_document(output)
      end


      it "calls #from_hash on the existing song instance, nothing else" do
        song_id = hit.song.object_id

        parse(hit, input)

        hit.song.title.must_equal "Suffer"
        hit.song.object_id.must_equal song_id
      end
    end
  end

  # FIXME: there's a bug with XML and the collection name!
  for_formats(
    :hash => [Representable::Hash, {"songs"=>[{"title"=>"Resist Stance"}]}, {"songs"=>[{"title"=>"Suffer"}]}],
    #:json => [Representable::JSON, "{\"song\":{\"name\":\"Alive\"}}", "{\"song\":{\"name\":\"You've Taken Everything\"}}"],
    :xml  => [Representable::XML, "<open_struct><song><title>Resist Stance</title></song></open_struct>", "<open_struct><songs><title>Suffer</title></songs></open_struct>"],
    :yaml => [Representable::YAML, "---\nsongs:\n- title: Resist Stance\n", "---\nsongs:\n- title: Suffer\n"],
  ) do |format, mod, output, input|

    describe "[#{format}] collection with :parse_strategy: :sync" do # TODO: introduce :representable option?
      let (:format) { format }
      representer!(:module => mod, :name => :song_representer) do
        property :title
        self.representation_wrap = :song if format == :xml
      end

      representer!(:inject => :song_representer, :module => mod) do
        collection :songs, :parse_strategy => :sync, :extend => song_representer
      end

      let (:album) { OpenStruct.new(:songs => [song]).extend(representer) }

      it "calls #to_hash on song instances, nothing else" do
        render(album).must_equal_document(output)
      end

      it "calls #from_hash on the existing song instance, nothing else" do
        collection_id = album.songs.object_id
        song          = album.songs.first
        song_id       = song.object_id

        parse(album, input)

        album.songs.first.title.must_equal "Suffer"
        song.title.must_equal "Suffer"
        #album.songs.object_id.must_equal collection_id # TODO: don't replace!
        song.object_id.must_equal song_id
      end
    end
  end


  # Lonely Collection
  require "representable/hash/collection"

  for_formats(
    :hash => [Representable::Hash::Collection, [{"title"=>"Resist Stance"}], [{"title"=>"Suffer"}]],
    # :xml  => [Representable::XML, "<open_struct><song><title>Resist Stance</title></song></open_struct>", "<open_struct><songs><title>Suffer</title></songs></open_struct>"],
  ) do |format, mod, output, input|

    describe "[#{format}] lonely collection with :parse_strategy: :sync" do # TODO: introduce :representable option?
      let (:format) { format }
      representer!(:module => Representable::Hash, :name => :song_representer) do
        property :title
        self.representation_wrap = :song if format == :xml
      end

      representer!(:inject => :song_representer, :module => mod) do
        items :parse_strategy => :sync, :extend => song_representer
      end

      let (:album) { [song].extend(representer) }

      it "calls #to_hash on song instances, nothing else" do
        render(album).must_equal_document(output)
      end

      it "calls #from_hash on the existing song instance, nothing else" do
        #collection_id = album.object_id
        song          = album.first
        song_id       = song.object_id

        parse(album, input)

        album.first.title.must_equal "Suffer"
        song.title.must_equal "Suffer"
        song.object_id.must_equal song_id
      end
    end
  end
end