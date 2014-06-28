require 'test_helper'

class FeaturesTest < MiniTest::Spec
  module Title
    def title; "Is It A Lie"; end
  end
  module Length
    def length; "2:31"; end
  end

  representer! do
    include Title
    include Length

    representable_attrs.directives[:features][Title]= true
    representable_attrs.directives[:features][Length]= true

    property :title
    property :length
    property :details do
      property :title
    end
  end

  it { OpenStruct.new(:details => Object.new).extend(representer).to_hash.must_equal({"title"=>"Is It A Lie", "length"=>"2:31", "details"=>{"title"=>"Is It A Lie"}}) }
end