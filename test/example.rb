require 'bundler'
Bundler.setup

require 'representable/yaml'
require 'ostruct'

class Song < OpenStruct
end

song = Song.new(:title => "Fallout", :track => 1)

require 'representable/json'
module SongRepresenter
  include Representable::JSON

  property :title
  property :track
end

puts song.extend(SongRepresenter).to_json

rox = Song.new.extend(SongRepresenter).from_json(%{ {"title":"Roxanne"} })
puts rox.inspect

module SongRepresenter
  include Representable::JSON

  self.representation_wrap= :hit

  property :title
  property :track
end

puts song.extend(SongRepresenter).to_json



######### collections

module SongRepresenter
  include Representable::JSON

  self.representation_wrap= false
end

module SongRepresenter
  include Representable::JSON

  property :title
  property :track
  collection :composers
end


song = Song.new(:title => "Fallout", :composers => ["Steward Copeland", "Sting"])
puts song.extend(SongRepresenter).to_json


######### nesting types

class Album < OpenStruct
end

module AlbumRepresenter
  include Representable::JSON

  property :name
  property :song, :extend => SongRepresenter, :class => Song
end

album = Album.new(:name => "The Police", :song => song)
puts album.extend(AlbumRepresenter).to_json


module AlbumRepresenter
  include Representable::JSON

  property :name
  collection :songs, :extend => SongRepresenter, :class => Song
end

album = Album.new(:name => "The Police", :songs => [song, Song.new(:title => "Synchronicity")])
puts album.extend(AlbumRepresenter).to_json


### XML
require 'representable/xml'
module SongRepresenter
  include Representable::XML

  property :title
  property :track
  collection :composers
end
song = Song.new(:title => "Fallout", :composers => ["Steward Copeland", "Sting"])
puts song.extend(SongRepresenter).to_xml


### YAML
require 'representable/yaml'
module SongRepresenter
  include Representable::YAML

  property :title
  property :track
  collection :composers
end
puts song.extend(SongRepresenter).to_yaml


class HotBands < OpenStruct
end


module SongRepresenter
  include Representable::YAML

  property :title
  property :track
end

module AlbumRepresenter
  include Representable::YAML

  property :name
  collection :songs, :extend => SongRepresenter, :class => Song
end

module HotBandsRepresenter
  include Representable::YAML

  property :for
  collection :names, :style => :flow
end

puts HotBands.new(:for => "Nick", :names => ["Bad Religion", "Van Halen", "Mozart"]).extend(HotBandsRepresenter).to_yaml


puts Album.new(:songs => [Song.new(:title => "Alltax", :track => 7)]).extend(AlbumRepresenter).to_yaml


######### custom methods in representer
######### inheritance