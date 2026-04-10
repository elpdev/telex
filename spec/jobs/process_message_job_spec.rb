require "rails_helper"

RSpec.describe ProcessMessageJob, type: :job do
  it "marks a message processed when the pipeline succeeds" do
    message = create(:message)
    allow(Inbound::Pipeline).to receive(:call) do |context|
      context.metadata["processed"] = true
    end

    described_class.perform_now(message)

    expect(message.reload).to be_processed
    expect(message.metadata).to include("processed" => true)
  end

  it "captures failures on the message" do
    message = create(:message)
    allow(Inbound::Pipeline).to receive(:call).and_raise(Inbound::NonRetryableError, "bad pipeline")

    described_class.perform_now(message)

    expect(message.reload).to be_failed
    expect(message.processing_error).to include("bad pipeline")
  end
end
