require "test_helper"

class PipelineTest < MiniTest::Spec
  Passthrough   = ->(fragment:) {  }
  SetResult     = ->(fragment:, **o) { "object from #{fragment}" }
  ModifyResult  = ->(result:, **o) { "modified #{result}" }

  it "linear" do
    pipeline = Representable::Pipeline[Passthrough, SetResult, ModifyResult]
    pipeline.(fragment: "yo!").must_equal "modified object from yo!"
  end

  Stopping      = ->(fragment:, result:, **o) { return Representable::Pipeline::Stop if fragment == "stop!"
    result }

  it "stopping" do
    pipeline = Representable::Pipeline[SetResult, Stopping, ModifyResult]
    pipeline.(fragment: "oy!").must_equal "modified object from oy!"
    pipeline.(fragment: "stop!").must_equal Representable::Pipeline::Stop
  end

  describe "nested Collect" do
    let(:pipeline) { Representable::Pipeline[Representable::Collect[SetResult, Stopping, ModifyResult]] }

    it { pipeline.(fragment: ["yo!", "oy!"]).must_equal ["modified object from yo!", "modified object from oy!"] }
    it { pipeline.(fragment: ["yo!", "stop!", "oy!"]).must_equal ["modified object from yo!", "modified object from oy!"] }
  end
end