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

  describe "passes options to all functions" do
    PrintOptions = ->(options) { options.to_s }
    PassOptions = ->(options) { options.to_a }

    it do
      Representable::Pipeline[PrintOptions, PassOptions].(key: true).must_equal([[:key, true], [:result, "{:key=>true}"]])
    end

    it do
      Representable::Pipeline[Representable::Collect[PrintOptions, PassOptions]].(fragment: [{key: true}, {second: true}]).
        must_equal([[[:fragment, {:key=>true}], [:index, 0], [:result, "{:fragment=>{:key=>true}, :index=>0}"]], [[:fragment, {:second=>true}], [:index, 1], [:result, "{:fragment=>{:second=>true}, :index=>1}"]]])
    end
  end


  # describe "Debug" do
  #   it do
  #     pipe = Representable::Pipeline[SetResult, Stopping, ModifyResult].extend(Representable::Pipeline::Debug)
  #     pipe.to_s.must_match "pipeline_test.rb:5 (lambda)>, #<Proc:"
  #   end

  #   it do
  #     pipe = Representable::Pipeline[Representable::Collect[SetResult, Stopping, ModifyResult]].extend(Representable::Pipeline::Debug)
  #     pipe.inspect.must_equal "asd"
  #   end
  #   # pipe = Representable::Pipeline[Representable::Collect[SetResult, Stopping, ModifyResult]]

  # end
end