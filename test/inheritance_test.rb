require 'test_helper'

class InheritanceTest < MiniTest::Spec
  let (:decorator) do
    Class.new(Representable::Decorator) do
      property :title
    end
  end

  # Decorator.new.representable_attrs != Decorator.representable_attrs
  it "doesn't clone for instantiated decorator" do
    instance = decorator.new(Object.new)
    instance.send(:representable_attrs).first.options[:instance] = true

    # we didn't clone and thereby change the original config:
    instance.send(:representable_attrs).to_s.must_equal decorator.representable_attrs.to_s
  end

  # TODO:  ? (performance?)
  #  more tests on cloning
  #
end
