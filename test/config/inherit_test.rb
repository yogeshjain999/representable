require 'test_helper'


class ConfigInheritTest < MiniTest::Spec
  # class Object

  # end

  module BandRepresenter

  end

  # in module
  module Module
    include Representable
    property :title
  end

  it { Module.representable_attrs[:definitions].keys.must_equal ["title"] }


  # in module including module
  module SubModule
    include Representable
    include Module

    property :location
  end

  it { SubModule.representable_attrs[:definitions].keys.must_equal ["title", "location"] }

  # including preserves order
  module IncludingModule
    include Representable
    property :genre
    include Module

    property :location
  end

  it { IncludingModule.representable_attrs[:definitions].keys.must_equal ["genre", "title", "location"] }


  # included in class
  class Class
    include Representable
    include IncludingModule
  end

  it { Class.representable_attrs[:definitions].keys.must_equal ["genre", "title", "location"] }

  # included in class with order
  class DefiningClass
    include Representable
    property :street_cred
    include IncludingModule
  end

  it { DefiningClass.representable_attrs[:definitions].keys.must_equal ["street_cred", "genre", "title", "location"] }

  # in class
  class RepresenterClass
    include Representable
    property :title
  end

  it { RepresenterClass.representable_attrs[:definitions].keys.must_equal ["title"] }


  # in inheriting class
  class InheritingRepresenterClass < RepresenterClass
    include Representable
    property :location
  end

  it { InheritingRepresenterClass.representable_attrs[:definitions].keys.must_equal ["title", "location"] }

  # in inheriting class and including
  module GenreModule
    include Representable
    property :genre
  end

  class InheritingAndIncludingClass < RepresenterClass
    property :location
    include GenreModule
  end

  it { InheritingAndIncludingClass.representable_attrs[:definitions].keys.must_equal ["title", "location", "genre"] }
end