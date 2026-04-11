require "rails_helper"

RSpec.describe Inbound::Pipeline do
  let(:message) { create(:message) }
  let(:context) do
    Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: message.inbox,
      message: message,
      subaddress: nil,
      metadata: {}
    )
  end

  let(:order) { [] }

  before do
    stub_const("Inbound::Processors::FirstProcessor", Class.new(Inbound::Processors::Base) do
      class_attribute :calls, default: nil
      define_method(:call) { self.class.calls << :first }
    end)

    stub_const("Inbound::Processors::SecondProcessor", Class.new(Inbound::Processors::Base) do
      class_attribute :calls, default: nil
      define_method(:call) { self.class.calls << :second }
    end)

    stub_const("Inbound::Processors::BestEffortProcessor", Class.new(Inbound::Processors::Base) do
      continue_on_error!
      define_method(:call) { raise "best effort failure" }
    end)

    stub_const("Inbound::Processors::FailingProcessor", Class.new(Inbound::Processors::Base) do
      define_method(:call) { raise "boom" }
    end)

    stub_const("Inbound::Processors::HaltingProcessor", Class.new(Inbound::Processors::Base) do
      define_method(:call) { halt! }
    end)

    Inbound::Processors::FirstProcessor.calls = order
    Inbound::Processors::SecondProcessor.calls = order
  end

  it "runs processors in order" do
    described_class.call(context, processors: [Inbound::Processors::FirstProcessor, Inbound::Processors::SecondProcessor])

    expect(order).to eq([:first, :second])
  end

  it "aborts on processor errors by default" do
    expect {
      described_class.call(context, processors: [Inbound::Processors::FirstProcessor, Inbound::Processors::FailingProcessor])
    }.to raise_error(Inbound::ProcessorError, /FailingProcessor failed/)

    expect(order).to eq([:first])
  end

  it "continues for best effort processors" do
    described_class.call(context, processors: [Inbound::Processors::BestEffortProcessor, Inbound::Processors::SecondProcessor])

    expect(context.metadata["processor_errors"].first["processor"]).to eq("Inbound::Processors::BestEffortProcessor")
    expect(order).to eq([:second])
  end

  it "stops after a processor halts the context" do
    described_class.call(context, processors: [Inbound::Processors::HaltingProcessor, Inbound::Processors::SecondProcessor])

    expect(context).to be_halted
    expect(order).to eq([])
  end
end
