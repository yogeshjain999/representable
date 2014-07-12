require 'test_helper'

class SchemaTest < MiniTest::Spec
  module Genre
    include Representable
    property :genre
  end

  module Module
    include Representable
    feature Representable

    property :title
    property :label do # extend: LabelModule
      # include Representable
      # include Representable::Hash # commenting that breaks (no #to_hash for <Label>)
      property :name
    end

    include Genre # Schema::Included::included is called!
  end


  class Decorator < Representable::Decorator
    feature Representable::Hash

    include Module
  end

  # puts Decorator.representable_attrs[:definitions].inspect

  let (:label) { OpenStruct.new(:name => "Fat Wreck", :city => "San Francisco", :employees => [OpenStruct.new(:name => "Mike")]) }
  let (:band) { OpenStruct.new(:genre => "Punkrock", :label => label) }


  # it { FlatlinersDecorator.new( OpenStruct.new(label: OpenStruct.new) ).
  #   to_hash.must_equal({}) }
  it do
    Decorator.new(band).to_hash.must_equal({"genre"=>"Punkrock", "label"=>{"name"=>"Fat Wreck"}})
  end


  class InheritDecorator < Representable::Decorator
    include Representable::Hash

    include Module

    property :label, inherit: true do # decorator.rb:27:in `initialize': superclass must be a Class (Module given)
      property :city
    end
  end

  it do
    InheritDecorator.new(band).to_hash.must_equal({"genre"=>"Punkrock", "label"=>{"name"=>"Fat Wreck", "city"=>"San Francisco"}})
  end



  class InheritFromDecorator < InheritDecorator

    property :label, inherit: true do
      collection :employees do
        property :name
      end
    end
  end

  it do
    InheritFromDecorator.new(band).to_hash.must_equal({"genre"=>"Punkrock", "label"=>{"name"=>"Fat Wreck", "city"=>"San Francisco", "employees"=>[{"name"=>"Mike"}]}})
  end
end