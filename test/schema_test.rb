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
    include Representable::Hash

    def self.inline_for(mod)
      Class.new(self) { include mod; self }
    end

    include Module

    def representable_attrs # for instances
      @bla ||= begin
        # TODO: do once!
        attrs = super
        attrs.each do |cfg|
          next unless mod = cfg.representer_module # only nested decorator.

          inline_representer = self.class.inline_for(mod) # the includer controls what "wraps" the module.
          cfg.merge!(:extend => inline_representer)
        end

        attrs
      end
    end

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

    def self.inline_for(mod)
      Class.new(self) { include mod; self }
    end

    include Module

    property :label, inherit: true do # decorator.rb:27:in `initialize': superclass must be a Class (Module given)
      property :city
    end
  end

  it do
    InheritDecorator.new(band).to_hash.must_equal({"genre"=>"Punkrock", "label"=>{"name"=>"Fat Wreck", "city"=>"San Francisco"}})
  end
end