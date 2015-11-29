# Representable

Representable maps Ruby objects to documents and back.

[![Gitter Chat](https://badges.gitter.im/trailblazer/chat.svg)](https://gitter.im/trailblazer/chat)
[![Build
Status](https://travis-ci.org/apotonick/representable.svg)](https://travis-ci.org/apotonick/representable)
[![Gem Version](https://badge.fury.io/rb/representable.svg)](http://badge.fury.io/rb/representable)

In other words: Take an object and decorate it with a representer module. This will allow you to render a JSON, XML or YAML document from that object. But that's only half of it! You can also use representers to parse a document and create or populate an object.

Representable is helpful for all kind of mappings, rendering and parsing workflows. However, it is mostly useful in API code. Are you planning to write a real REST API with representable? Then check out the [Roar](http://github.com/apotonick/roar) gem first, save work and time and make the world a better place instead.


## Installation

The representable gem runs with all Ruby versions >= 1.9.3.

```ruby
gem 'representable'
```

### Dependencies

Representable does a great job with JSON, it also features support for XML, YAML and pure ruby
hashes. But Representable did not bundle dependencies for JSON and XML.

If you want to use JSON, add the following to your Gemfile:

```ruby
gem 'multi_json'
```

If you want to use XML, add the following to your Gemfile:

```ruby
gem 'nokogiri'
```

## Example

What if we're writing an API for music - songs, albums, bands.

```ruby
class Song < OpenStruct
end

song = Song.new(title: "Fallout", track: 1)
```

## Defining Representations

Representations are defined using representer modules.

```ruby
require 'representable/json'

module SongRepresenter
  include Representable::JSON

  property :title
  property :track
end
```

In the representer the #property method allows declaring represented attributes of the object. All the representer requires for rendering are readers on the represented object, e.g. `#title` and `#track`. When parsing, it will call setters - in our example, that'd be `#title=` and `#track=`.


## Rendering

Mixing in the representer into the object adds a rendering method.

```ruby
song.extend(SongRepresenter).to_json
#=> {"title":"Fallout","track":1}
```

## Parsing

It also adds support for parsing.

```ruby
song = Song.new.extend(SongRepresenter).from_json(%{ {"title":"Roxanne"} })
#=> #<Song title="Roxanne", track=nil>
```

Note that parsing hashes per default does [require string keys](#symbol-keys-vs-string-keys) and does _not_ pick up symbol keys.

## Extend vs. Decorator

If you don't want representer modules to be mixed into your objects (using `#extend`) you can use the `Decorator` strategy [described below](#decorator-vs-extend). Decorating instead of extending was introduced in 1.4.




## Collections

Let's add a list of composers to the song representation.

```ruby
module SongRepresenter
  include Representable::JSON

  property :title
  property :track
  collection :composers
end
```

Surprisingly, `#collection` lets us define lists of objects to represent.

```ruby
Song.new(title: "Fallout", composers: ["Stewart Copeland", "Sting"]).
  extend(SongRepresenter).to_json

#=> {"title":"Fallout","composers":["Stewart Copeland","Sting"]}
```

And again, this works both ways - in addition to the title it extracts the composers from the document, too.


## Nesting

Representers can also manage compositions. Why not use an album that contains a list of songs?

```ruby
class Album < OpenStruct
end

album = Album.new(name: "The Police", songs: [song, Song.new(title: "Synchronicity")])
```

Here comes the representer that defines the composition.

```ruby
module AlbumRepresenter
  include Representable::JSON

  property :name
  collection :songs, extend: SongRepresenter, class: Song
end
```

## Suppressing Nested Wraps

When reusing a representer for a nested document, you might want to suppress the wrap for the nested fragment.

```ruby
module SongRepresenter
  include Representable::JSON

  self.representation_wrap = :songs
  property :title
end
```

When reusing `SongRepresenter` in a nested setup you can suppress the wrapping using the `:wrap` option.

```ruby
module AlbumRepresenter
  include Representable::JSON

  collection :songs, extend: SongRepresenter, wrap: false
end
```

The `representation_wrap` from the nested representer now won't be rendered and parsed.

```ruby
album.extend(AlbumRepresenter).to_json #=> "{\"songs\": [{\"name\": \"Roxanne\"}]}"
```

Note that this only works for JSON and Hash at the moment.


## Inline Representers

If you don't want to maintain two separate modules when nesting representations you can define the `SongRepresenter` inline.

```ruby
module AlbumRepresenter
  include Representable::JSON

  property :name

  collection :songs, class: Song do
    property :title
    property :track
    collection :composers
  end
```
## Feature

If you need to include modules in all inline representers automatically, register it as a feature.

```ruby
module AlbumRepresenter
  include Representable::JSON
  feature Link # imports ::link

  link "/album/1"

  property :hit do
    link "/hit/1" # link method imported automatically.
  end
```


## Representing Singular Models And Collections

You can explicitly define representers for collections of models using a ["Lonely Collection"](#lonely-collections). Or you can let representable  do that for you.

Rendering a collection of objects comes for free, using `::for_collection`.

```ruby
  Song.all.extend(SongRepresenter.for_collection).to_hash
  #=> [{title: "Sevens"}, {title: "Eric"}]
```

For parsing, you need to provide the class constant to which the items should be deserialized to.

```ruby
module SongRepresenter
  include Representable::Hash
  property :title

  collection_representer class: Song
end
```

You can now parse collections to `Song` instances.

```ruby
[].extend(SongRepresenter.for_collection).from_hash([{title: "Sevens"}, {title: "Eric"}])
```

As always, this works for decorators _and_ modules.

In case you don't want to know whether or not you're working with a collection or singular model, use `::represent`.

```ruby
# singular
SongRepresenter.represent(Song.find(1)).to_hash #=> {title: "Sevens"}

# collection
SongRepresenter.represent(Song.all).to_hash #=> [{title: "Sevens"}, {title: "Eric"}]
```

As you can see, `::represent` figures out the correct representer for you (works also for parsing!).

Note: the implicit collection representer internally is implemented using a lonely collection. Everything you pass to `::collection_representer` is simply provided to the `::items` call in the lonely collection. That allows you to use `:parse_strategy` and all the other goodies, too.


### Methods In Decorators

When adding a method to a decorator, representable will still invoke accessors on the represented instance - unless you tell it the scope.

```ruby
class SongRepresenter < Representable::Decorator
  property :title, exec_context: :decorator

  def title
    represented.name
  end
end
```


## Callable Options

While lambdas are one option for dynamic options, you might also pass a "callable" object to a directive.

```ruby
class Sanitizer
  include Uber::Callable

  def call(represented, fragment, doc, *args)
    fragment.sanitize
  end
end
```

Note how including `Uber::Callable` marks instances of this class as callable. No `respond_to?` or other magic takes place here.

```ruby
property :title, parse_filter: Santizer.new
```

This is enough to have the `Sanitizer` class run with all the arguments that are usually passed to the lambda (preceded by the represented object as first argument).





## Hashes

As an addition to single properties and collections representable also offers to represent hash attributes.

```ruby
module SongRepresenter
  include Representable::JSON

  property :title
  hash :ratings
end

Song.new(title: "Bliss", ratings: {"Rolling Stone" => 4.9, "FryZine" => 4.5}).
extend(SongRepresenter).to_json

#=> {"title":"Bliss","ratings":{"Rolling Stone":4.9,"FryZine":4.5}}
```

## Lonely Hashes

Need to represent a bare hash without any container? Use the `JSON::Hash` representer (or XML::Hash).

```ruby
require 'representable/json/hash'

module FavoriteSongsRepresenter
  include Representable::JSON::Hash
end

{"Nick" => "Hyper Music", "El" => "Blown In The Wind"}.extend(FavoriteSongsRepresenter).to_json
#=> {"Nick":"Hyper Music","El":"Blown In The Wind"}
```

Works both ways. The values are configurable and might be self-representing objects in turn. Tell the `Hash` by using `#values`.

```ruby
module FavoriteSongsRepresenter
  include Representable::JSON::Hash

  values extend: SongRepresenter, class: Song
end

{"Nick" => Song.new(title: "Hyper Music")}.extend(FavoriteSongsRepresenter).to_json
```

In XML, if you want to store hash attributes in tag attributes instead of dedicated nodes, use `XML::AttributeHash`.

## Lonely Collections

Same goes with arrays.

```ruby
require 'representable/json/collection'

module SongsRepresenter
  include Representable::JSON::Collection

  items extend: SongRepresenter, class: Song
end
```

The `#items` method lets you configure the contained entity representing here.

```ruby
[Song.new(title: "Hyper Music"), Song.new(title: "Screenager")].extend(SongsRepresenter.for_collection).to_json
#=> [{"title":"Hyper Music"},{"title":"Screenager"}]
```

Note that this also works for XML.


## YAML Support

Representable also comes with a YAML representer.

```ruby
module SongRepresenter
  include Representable::YAML

  property :title
  property :track
  collection :composers, :style => :flow
end
```

A nice feature is that `#collection` also accepts a `:style` option which helps having nicely formatted inline (or "flow") arrays in your YAML - if you want that!

```ruby
song.extend(SongRepresenter).to_yaml
#=>
---
title: Fallout
composers: [Stewart Copeland, Sting]
```


### Read/Write Restrictions

Using the `:readable` and `:writeable` options access to properties can be restricted.

```ruby
property :title, :readable => false
```

This will leave out the `title` property in the rendered document. Vice-versa, `:writeable` will skip the property when parsing and does not assign it.




## Coercion

If you fancy coercion when parsing a document you can use the Coercion module which uses [virtus](https://github.com/solnic/virtus) for type conversion.

Include virtus in your Gemfile, first. Be sure to include virtus 0.5.0 or greater.

```ruby
gem 'virtus', ">= 0.5.0"
```

Use the `:type` option to specify the conversion target. Note that `:default` still works.

```ruby
module SongRepresenter
  include Representable::JSON
  include Representable::Coercion

  property :title
  property :recorded_at, :type => DateTime, :default => "May 12th, 2012"
end
```

In a decorator it works alike.

```ruby
class SongRepresenter < Representable::Decorator
  include Representable::JSON
  include Representable::Coercion

  property :recorded_at, :type => DateTime
end
```

Coercing values only happens when rendering or parsing a document. Representable does not create accessors in your model as `virtus` does.



### Skipping Rendering Or Parsing

You can skip to call to `#to_hash`/`#from_hash` on the prepared object by using `:representable`.

```ruby
property :song, :representable => false
```

This will run the entire serialization/deserialization _without_ calling the actual representing method on the object.

Extremely helpful if you wanna use representable as a data mapping tool with filtering, aliasing, etc., without the rendering and parsing part.


### Decorator In Module

Inline representers defined in a module can be implemented as a decorator, thus wrapping the represented object without pollution.

```ruby
property :song, use_decorator: true do
  property :title
end
```

This is an implementation detail most people shouldn't worry about.


## Symbol Keys vs. String Keys

When parsing representable reads properties from hashes by using their string keys.

```ruby
song.from_hash("title" => "Road To Never")
```

To allow symbol keys also include the `AllowSymbols` module.

```ruby
module SongRepresenter
  include Representable::Hash
  include Representable::Hash::AllowSymbols
  # ..
end
```

This will give you a behavior close to Rails' `HashWithIndifferentAccess` by stringifying the incoming hash internally.


## Debugging

Representable is a generic mapper using recursions and things that might be hard to understand from the outside. That's why we got the `Debug` module which will give helpful output about what it's doing when parsing or rendering.

You can extend objects on the run to see what they're doing.

```ruby
song.extend(SongRepresenter).extend(Representable::Debug).from_json("..")
song.extend(SongRepresenter).extend(Representable::Debug).to_json
```

`Debug` can also be included statically into your representer or decorator.

```ruby
class SongRepresenter < Representable::Decorator
  include Representable::JSON
  include Representable::Debug

  property :title
end
```

It's probably a good idea not to do this in production.


## Copyright

Representable started as a heavily simplified fork of the ROXML gem. Big thanks to Ben Woosley for his inspiring work.

* Copyright (c) 2011-2015 Nick Sutterer <apotonick@gmail.com>
* ROXML is Copyright (c) 2004-2009 Ben Woosley, Zak Mandhro and Anders Engstrom.

Representable is released under the [MIT License](http://www.opensource.org/licenses/MIT).
