require "rails_helper"

RSpec.describe DeliverOutboundMessageJob, type: :job do
  it "marks a queued message sent when delivery succeeds" do
    outbound_message = create(:outbound_message, status: :queued, queued_at: Time.current)

    described_class.perform_now(outbound_message)

    expect(outbound_message.reload).to be_sent
    expect(outbound_message.delivery_attempts).to eq(1)
    expect(outbound_message.sent_at).to be_present
  end

  it "marks the message failed when the domain configuration is invalid" do
    outbound_message = create(:outbound_message, domain: create(:domain), status: :queued, queued_at: Time.current)

    described_class.perform_now(outbound_message)

    expect(outbound_message.reload).to be_failed
    expect(outbound_message.last_error).to include("Outbound::ConfigurationError")
    expect(outbound_message.last_error).to include("outbound_from_name can't be blank")
  end

  it "marks the message failed when retries are exhausted" do
    outbound_message = create(:outbound_message, status: :queued, queued_at: Time.current)

    allow(Outbound::Sender).to receive(:deliver!).and_raise(Net::ReadTimeout, "timed out")

    perform_enqueued_jobs do
      described_class.perform_later(outbound_message)
    end

    expect(outbound_message.reload).to be_failed
    expect(outbound_message.delivery_attempts).to eq(5)
    expect(outbound_message.last_error).to include("Net::ReadTimeout")
  end
end
