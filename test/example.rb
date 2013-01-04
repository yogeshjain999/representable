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
  def name
    puts @table.inspect
    #@attributes
    @table[:name]
  end
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


SongRepresenter.module_eval do
  @representable_attrs = nil
end


######### using helpers (customizing the rendering/parsing) 
module AlbumRepresenter
  def name
    super.upper
  end
end
album = Album.new(:name => "The Police", :songs => [song, Song.new(:title => "Synchronicity")])
puts album.extend(AlbumRepresenter).to_json

SongRepresenter.module_eval do
  @representable_attrs = nil
end


######### inheritance
module SongRepresenter
  include Representable::JSON

  property :title
  property :track
end

module CoverSongRepresenter
  include Representable::JSON
  include SongRepresenter

  property :covered_by
end


song = Song.new(:title => "Truth Hits Everybody", :covered_by => "No Use For A Name")
puts song.extend(CoverSongRepresenter).to_json


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


SongRepresenter.module_eval do
  @representable_attrs = nil
end


### YAML
require 'representable/yaml'
module SongRepresenter
  include Representable::YAML

  property :title
  property :track
  collection :composers
end
puts song.extend(SongRepresenter).to_yaml


SongRepresenter.module_eval do
  @representable_attrs = nil
end


### YAML
module SongRepresenter
  include Representable::YAML

  property :title
  property :track
  collection :composers, :style => :flow
end
puts song.extend(SongRepresenter).to_yaml


######### custom methods in representer (using helpers)
######### r/w, conditions
#########
######### polymorphic :extend and :class, instance context!, :instance