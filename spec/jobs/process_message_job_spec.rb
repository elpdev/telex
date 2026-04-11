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

  it "extracts calendar invitation metadata during normal processing" do
    user = create(:user, email_address: "leo@example.com")
    inbox = create(:inbox, local_part: "inbox")
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(
      build_calendar_invitation_email(to: inbox.address, attendee_email: user.email_address)
    )
    message = Inbound::Ingestor.ingest!(inbound_email, inbox: inbox)

    described_class.perform_now(message)

    expect(message.reload).to be_processed
    expect(message.metadata.dig("calendar_invitation", "uid")).to eq("invite-1")
    expect(message.metadata.fetch("tags", [])).to include("calendar_invitation")
  end
end
