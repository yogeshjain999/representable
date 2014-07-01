require 'test_helper'

class FilterPipelineTest < MiniTest::Spec
  let (:block1) { lambda { |value, *| "1: #{value}" } }
  let (:block2) { lambda { |value, *| "2: #{value}" } }

  subject { Representable::Pipeline[block1, block2] }

  it { subject.call(Object, "Horowitz").must_equal "2: 1: Horowitz" }
end