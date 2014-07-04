require 'test_helper'

class ConfigTest < MiniTest::Spec
  subject { Representable::Config.new }
  PunkRock = Class.new
  Definition = Representable::Definition

  describe "wrapping" do
    it "returns false per default" do
      assert_equal nil, subject.wrap_for("Punk", nil)
    end

    it "infers a printable class name if set to true" do
      subject.wrap = true
      assert_equal "punk_rock", subject.wrap_for(PunkRock, nil)
    end

    it "can be set explicitely" do
      subject.wrap = "Descendents"
      assert_equal "Descendents", subject.wrap_for(PunkRock, nil)
    end
  end

  describe "#[]" do
    before { subject[:title] = {:me => true} }

    it { subject[:unknown].must_equal     nil }
    it { subject[:title][:me].must_equal  true }
    it { subject["title"][:me].must_equal true }
  end

  # []=
  # deprecate <<
  # []=(... inherit: true)


  describe "#each" do
    before { subject[:title]= {:me => true} }

    it "what" do
      definitions = []
      subject.each { |dfn| definitions << dfn }
      definitions.size.must_equal 1
      definitions[0][:me].must_equal true
    end
  end

  describe "#options" do
    it { subject.options.must_equal({}) }
    it do
      subject.options[:namespacing] = true
      subject.options[:namespacing].must_equal true
    end
  end


  describe "#inherit!" do
    let (:title)  { Definition.new(:title) }
    let (:length) { Definition.new(:length) }
    let (:stars)  { Definition.new(:stars) }

    it do
      parent = Representable::Config.new
      parent << title
      parent.directives[:features][Object] = true
      # DISCUSS: build InheritableHash automatically in options? is there a gem for that?
      parent.options[:additional_features] = Representable::Config::InheritableHash[Object => true]

      subject.inherit!(parent)
      # add to inherited config:
      subject << stars
      subject.directives[:features][Module] = true
      subject.options[:additional_features][Module] = true

      subject.directives[:features].must_equal({Object => true, Module => true})

      parent.options[:additional_features].must_equal({Object => true})
      subject.options[:additional_features].must_equal({Object => true, Module => true})

      definitions = subject.instance_variable_get(:@definitions).values
      definitions.must_equal([title, stars])
      definitions[0].object_id.wont_equal title.object_id
      definitions[1].object_id.must_equal stars.object_id
    end
  end

  describe "#features" do
    it do
      subject.directives[:features][Object] = true
      subject.directives[:features][Module] = true

      subject.features.must_equal [Object, Module]
    end
  end
end


class ConfigInheritableTest < MiniTest::Spec
  # InheritableArray
  it do
    parent = Representable::Config::InheritableArray.new([1,2,3])
    child  = Representable::Config::InheritableArray.new([4])

    child.inherit!(parent).must_equal([4,1,2,3])
  end

  # InheritableHash
  InheritableHash = Representable::Config::InheritableHash
  describe "InheritableHash" do
    it do
      parent = InheritableHash[:volume => 9, :genre => "Powermetal"]
      child  = InheritableHash[:genre => "Metal", :pitch => 99]

      child.inherit!(parent).must_equal(:volume => 9, :genre => "Powermetal", :pitch => 99)
    end

    # clone all elements when inheriting.
    it "what" do
      parent = InheritableHash[:details => InheritableHash[:title => "Man Of Steel"]]
      child  = InheritableHash[].inherit!(parent)
      child[:details][:length] = 136

      parent.must_equal({:details => {:title => "Man Of Steel"}})
      child.must_equal( {:details => {:title => "Man Of Steel", :length => 136}})
    end
  end
end