require 'test_helper'




# Include Inherit Module And Decorator Test
class SchemaTest < MiniTest::Spec
  module Genre
    include Representable
    property :genre
  end

  module LinkFeature
    def self.included(base)
      base.extend(Link)
    end

    module Link
      def link
      end
    end
  end


  module Module
    include Representable::Hash
    feature LinkFeature

    property :title
    property :label do # extend: LabelModule
      property :name
      link # feature

      property :location do
        property :city
        link # feature.
      end
    end

    property :album, :extend => lambda { raise "don't manifest me!" } # this is not an inline decorator, don't manifest it.


    include Genre # Schema::Included::included is called!
  end


  class InheritDecorator < Representable::Decorator
    include Representable::Hash

    include Module

    property :label, inherit: true do # decorator.rb:27:in `initialize': superclass must be a Class (Module given)
      property :city

      property :location, :inherit => true do
        property :city
      end
    end
  end


  class InheritFromDecorator < InheritDecorator
    property :label, inherit: true do
      collection :employees do
        property :name
      end
    end
  end
end