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

  class FickenConfig < Representable::Config
    def inherit!(parent)
      puts "uuuuuuuu from #{parent}"
     res= super
      # we get the module and want to manifest inline modules into inline decorators of ours.
       manifest!(SchemaTest::Decorator)
      res
    end

    def manifest!(inheritor) # one level deep manifesting modules into Decorators.
      each do |cfg| # only definitions.
        next unless mod = cfg.representer_module # only nested decorator.

puts "manifesting for #{cfg.name}"
        inline_representer = inheritor.inline_for(mod) # the includer controls what "wraps" the module.
        cfg.merge!(:extend => inline_representer)
      end
    end
  end

  Representable::Decorator.class_eval do
    def self.build_config
      puts "in #{self}"
      FickenConfig.new
    end

    def self.inline_for(mod) # called in manifest!
      attrs = representable_attrs
      Class.new(Representable::Decorator) {
        include *attrs.features
        include mod; self }
    end
  end

  class Decorator < Representable::Decorator
    feature Representable::Hash

    include Module
  end

  # puts Decorator.representable_attrs[:definitions].inspect

  let (:label) { OpenStruct.new(:name => "Fat Wreck", :city => "San Francisco") }
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



  # class InheritFromDecorator < InheritDecorator

  #   property :label, inherit: true do
  #     collection :employees do

  #     end
  #   end
  # end
end