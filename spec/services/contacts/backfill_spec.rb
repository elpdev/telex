require "rails_helper"

RSpec.describe Contacts::Backfill do
  it "backfills contacts and communications for existing inbound and sent outbound messages" do
    user = create(:user)
    domain = create(:domain, :with_outbound_configuration, user: user, name: "example.test", outbound_from_address: "hello@example.test")
    inbox = create(:inbox, domain: domain)
    inbound_message = create(:message, inbox: inbox, from_address: "Sender@External.test", from_name: "Sender")
    outbound_message = create(:outbound_message, user: user, domain: domain, source_message: nil, to_addresses: ["Client@External.test"], status: :sent, sent_at: 1.hour.ago)

    result = described_class.call(user: user)

    expect(result.inbound_messages).to eq(1)
    expect(result.outbound_messages).to eq(1)
    expect(inbound_message.reload.contact.primary_email_address.email_address).to eq("sender@external.test")
    expect(user.contact_email_addresses.pluck(:email_address)).to include("sender@external.test", "client@external.test")
    expect(ContactCommunication.where(communicable: inbound_message).count).to eq(1)
    expect(ContactCommunication.where(communicable: outbound_message).count).to eq(1)
  end

  it "is idempotent" do
    user = create(:user)
    domain = create(:domain, user: user)
    inbox = create(:inbox, domain: domain)
    create(:message, inbox: inbox, from_address: "sender@example.com")

    described_class.call(user: user)

    expect {
      described_class.call(user: user)
    }.not_to change(ContactCommunication, :count)
  end
end
