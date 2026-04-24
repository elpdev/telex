require "rails_helper"

RSpec.describe OutboundMessage, type: :model do
  it "normalizes recipient lists when preparing delivery" do
    outbound_message = build(
      :outbound_message,
      status: :queued,
      to_addresses: [" USER@EXAMPLE.COM ", "user@example.com", ""],
      cc_addresses: [" CC@EXAMPLE.COM "],
      bcc_addresses: [" BCC@EXAMPLE.COM "]
    )

    expect(outbound_message).to be_valid
    expect(outbound_message.to_addresses).to eq(["user@example.com"])
    expect(outbound_message.cc_addresses).to eq(["cc@example.com"])
    expect(outbound_message.bcc_addresses).to eq(["bcc@example.com"])
  end

  it "allows incomplete drafts" do
    outbound_message = build(:outbound_message, to_addresses: [], subject: nil, status: :draft)

    expect(outbound_message).to be_valid
  end

  it "requires at least one recipient outside draft state" do
    outbound_message = build(:outbound_message, to_addresses: [], status: :queued)

    expect(outbound_message).not_to be_valid
    expect(outbound_message.errors[:to_addresses]).to include("can't be blank")
  end

  it "rejects invalid recipient addresses outside draft state" do
    outbound_message = build(:outbound_message, to_addresses: ["not-an-email"], status: :queued)

    expect(outbound_message).not_to be_valid
    expect(outbound_message.errors[:to_addresses]).to include("contains an invalid email address")
  end

  it "uses the inbox address as the outbound sender when present" do
    domain = create(:domain, :with_outbound_configuration, name: "domain.test")
    inbox = create(:inbox, domain: domain, local_part: "support")
    outbound_message = build(:outbound_message, domain: domain, inbox: inbox)

    expect(outbound_message.from_address).to eq("support@domain.test")
    expect(outbound_message.participant_addresses).to include("support@domain.test")
  end

  it "requires the selected inbox to belong to the outbound domain" do
    outbound_message = build(:outbound_message, inbox: create(:inbox))

    expect(outbound_message).not_to be_valid
    expect(outbound_message.errors[:inbox]).to include("must belong to domain")
  end

  it "enqueues delivery from a persisted record" do
    outbound_message = create(:outbound_message)

    expect {
      outbound_message.enqueue_delivery!
    }.to have_enqueued_job(DeliverOutboundMessageJob).with(outbound_message)

    expect(outbound_message.reload).to be_queued
    expect(outbound_message.queued_at).to be_present
  end
end
