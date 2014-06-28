require 'test_helper'

class ConfigTest < MiniTest::Spec
  subject { Representable::Config.new }
  PunkRock = Class.new
  Definition = Representable::Definition

  let (:definition) { Definition.new(:title) }

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

  describe "#<<" do
    it "returns Definition" do
      (subject << definition).must_equal definition
    end

    it "overwrites old property" do
      subject << definition
      subject << overrider = Representable::Definition.new(:title)

      subject.size.must_equal 1
      subject[:title].must_equal overrider
    end
  end

  describe "#[]" do
    before { subject << definition }

    it { subject[:unknown].must_equal nil }
    it { subject[:title].must_equal definition }
    it { subject["title"].must_equal definition }
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
      parent.features[Object] = true

      subject.inherit!(parent)
      subject << stars
      subject.features[Module] = true

      subject.features.must_equal({Object => true, Module => true})

      definitions = subject.instance_variable_get(:@definitions).values
      definitions.must_equal([title, stars])
      definitions[0].object_id.wont_equal title.object_id
      definitions[1].object_id.must_equal stars.object_id
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
  it do
    parent = Representable::Config::InheritableHash[:volume => 9, :genre => "Powermetal"]
    child  = Representable::Config::InheritableHash[:genre => "Metal", :pitch => 99]

    child.inherit!(parent).must_equal(:volume => 9, :genre => "Powermetal", :pitch => 99)
  end
end