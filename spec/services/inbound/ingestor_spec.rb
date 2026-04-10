require "rails_helper"

RSpec.describe Inbound::Ingestor do
  let(:domain) { create(:domain, name: "lbp.dev") }
  let(:inbox) { create(:inbox, domain: domain, local_part: "receipts") }

  it "persists bodies, attachments, and the subaddress" do
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(Rails.root.join("spec/fixtures/files/inbound/html_with_attachment.eml").read)

    message = described_class.ingest!(inbound_email, inbox: inbox, subaddress: "amazon")

    expect(message).to be_persisted
    expect(message.subaddress).to eq("amazon")
    expect(message.conversation).to be_present
    expect(message.text_body).to include("Thanks for your purchase")
    expect(message.body.to_plain_text).to include("Thanks for your purchase")
    expect(message.attachments.map(&:filename).map(&:to_s)).to include("receipt.txt")
  end

  it "is idempotent for the same inbound email" do
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(Rails.root.join("spec/fixtures/files/inbound/plain_text.eml").read)

    first = described_class.ingest!(inbound_email, inbox: inbox)
    second = described_class.ingest!(inbound_email, inbox: inbox)

    expect(first.id).to eq(second.id)
    expect(Message.count).to eq(1)
  end
end
