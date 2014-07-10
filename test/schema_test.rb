require 'test_helper'

class SchemaTest < MiniTest::Spec
  module Module
    include Representable::Schema

    property :title
    property :label do # extend: LabelModule
      # include Representable
      # include Representable::Hash # commenting that breaks (no #to_hash for <Label>)
      property :name
    end
  end

  class Decorator < Representable::Decorator
    include Representable::Hash

    def self.inline_for(mod)
      Class.new(self) { include mod; self }
    end

    include Module

  end

  # puts Decorator.representable_attrs[:definitions].inspect

  let (:label) { OpenStruct.new(:name => "Fat Wreck", :city => "San Francisco") }
  let (:band) { OpenStruct.new(:label => label) }


  # it { FlatlinersDecorator.new( OpenStruct.new(label: OpenStruct.new) ).
  #   to_hash.must_equal({}) }
  it do
    Decorator.new(band).to_hash.must_equal({"label"=>{"name"=>"Fat Wreck"}})
  end


  class InheritDecorator < Representable::Decorator
    include Representable::Hash

    def self.inline_for(mod)
      Class.new(self) { include mod; self }
    end

    include Module

    property :label, inherit: true do # decorator.rb:27:in `initialize': superclass must be a Class (Module given)
      property :city
    end
  end

  it do
    InheritDecorator.new(band).to_hash.must_equal({"label"=>{"name"=>"Fat Wreck", "city"=>"San Francisco"}})
  end
end