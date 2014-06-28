require 'test_helper'

# tested feature: ::property

class ConfigTest < MiniTest::Spec
  subject { Representable::Config.new }
  PunkRock = Class.new

  let (:definition) { Representable::Definition.new(:title) }

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
      subject.directives[:definitions][:title].must_equal overrider
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

  # child.inherit(parent)
  class InheritableArray < Array
    def inherit!(parent)
      push(*parent.clone)
    end
  end

  it "what" do
    parent = InheritableArray.new([1,2,3])
    child  = InheritableArray.new([4])

    child.inherit!(parent).must_equal([4,1,2,3])
  end


  # child.inherit(parent)
  class InheritableHash < Hash
    def inherit!(parent)
      merge!(parent.clone)
    end
  end

  it "whatyx" do
    parent = InheritableHash[:volume => 9, :genre => "Powermetal"]
    child  = InheritableHash[:genre => "Metal", :pitch => 99]

    child.inherit!(parent).must_equal(:volume => 9, :genre => "Powermetal", :pitch => 99)
  end

  D = Struct.new(:name)

  let (:title)  { D.new(:title) }
  let (:length) { D.new(:length) }
  let (:stars)  { D.new(:stars) }

  Definitions = Representable::Config::Definitions
  # test Definitions#clone and #inherit!.
  it "xxx" do
    parent = Definitions.new
    parent << title
    parent << length

    child = Definitions.new
    child << stars
    child.inherit!(parent)


    parent.values.must_equal [title, length]

    # make sure parent's definitions were cloned and added.
    child_defs = child.values
    child_defs.must_equal([stars, title, length])

    child_defs[0].object_id.must_equal stars.object_id
    child_defs[1].object_id.wont_equal title.object_id
    child_defs[2].object_id.wont_equal length.object_id
  end

  class Config
    def initialize
      @directives = {
        :features   => InheritableHash.new,
        :definitions => Definitions.new,
        :options    => InheritableHash.new
      }
    end
    attr_reader :directives

    def inherit!(parent)
      for directive in directives.keys
        directives[directive].inherit!(parent.directives[directive])
      end
    end
  end

  it "what" do
    parent = Config.new
    parent.directives[:definitions] << title
    parent.directives[:features][Object] = true

    config = Config.new
    config.inherit!(parent)
    config.directives[:definitions] << stars
    config.directives[:features][Module] = true

    config.directives[:features].must_equal({Object => true, Module => true})

    config.directives[:definitions].values.must_equal([title, stars])
    config.directives[:definitions].values[0].object_id.wont_equal title.object_id
  end
end