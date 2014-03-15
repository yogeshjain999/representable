require 'test_helper'

# tested feature: ::property

class ConfigTest < MiniTest::Spec
  subject { Representable::Config.new }
  PunkRock = Class.new

  let (:definition) { Representable::Definition.new(:title) }

  describe "wrapping" do
    it "returns false per default" do
      assert_equal nil, subject.wrap_for("Punk")
    end

    it "infers a printable class name if set to true" do
      subject.wrap = true
      assert_equal "punk_rock", subject.wrap_for(PunkRock)
    end

    it "can be set explicitely" do
      subject.wrap = "Descendents"
      assert_equal "Descendents", subject.wrap_for(PunkRock)
    end
  end

  describe "#cloned" do
    it "clones all definitions" do
      subject << obj = definition

      subject.cloned.map(&:name).must_equal ["title"]
      subject.cloned.first.object_id.wont_equal obj.object_id
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
      subject.first.must_equal overrider
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

  describe "Config inheritance" do
    # TODO: this section will soon be moved to uber.
    describe "inheritance when including" do
      # TODO: test all the below issues AND if cloning works.
      module TestMethods
        def representer_for(modules=[Representable], &block)
          Module.new do
            extend TestMethods
            include *modules
            module_exec(&block)
          end
        end
      end
      include TestMethods

      it "inherits to uninitialized child" do
        representer_for do # child
          include(representer_for do # parent
            representable_attrs.inheritable_array(:links) << "bar"
          end)
        end.representable_attrs.inheritable_array(:links).must_equal(["bar"])
      end

      it "works with uninitialized parent" do
        representer_for do # child
          representable_attrs.inheritable_array(:links) << "bar"

          include(representer_for do # parent
          end)
        end.representable_attrs.inheritable_array(:links).must_equal(["bar"])
      end

      it "inherits when both are initialized" do
        representer_for do # child
          representable_attrs.inheritable_array(:links) << "bar"

          include(representer_for do # parent
            representable_attrs.inheritable_array(:links) << "stadium"
          end)
        end.representable_attrs.inheritable_array(:links).must_equal(["bar", "stadium"])
      end

      it "clones parent inheritables" do # FIXME: actually we don't clone here!
        representer_for do # child
          representable_attrs.inheritable_array(:links) << "bar"

          include(parent = representer_for do # parent
            representable_attrs.inheritable_array(:links) << "stadium"
          end)

          parent.representable_attrs.inheritable_array(:links) << "park"  # modify parent array.

        end.representable_attrs.inheritable_array(:links).must_equal(["bar", "stadium"])
      end
    end
  end
end