require "rails_helper"

RSpec.describe Inbound::Router do
  let!(:home_inbox) { create(:inbox, domain: create(:domain, name: "lbp.dev"), local_part: "home") }
  let!(:receipts_inbox) { create(:inbox, domain: home_inbox.domain, local_part: "receipts", pipeline_key: "receipts") }

  after do
    described_class.clear(@inbound_email) if defined?(@inbound_email) && @inbound_email.present?
  end

  it "matches a plus addressed recipient" do
    @inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(Rails.root.join("spec/fixtures/files/inbound/subaddressed.eml").read)

    match = described_class.match(@inbound_email)

    expect(match.inbox).to eq(receipts_inbox)
    expect(match.subaddress).to eq("amazon")
  end

  it "falls back to delivered-to headers" do
    @inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(Rails.root.join("spec/fixtures/files/inbound/delivered_to_only.eml").read)

    match = described_class.match(@inbound_email)

    expect(match.inbox).to eq(home_inbox)
  end

  it "returns nil when no inbox matches" do
    @inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(<<~EMAIL)
      From: Sender <sender@example.com>
      To: nobody@lbp.dev
      Subject: No match
      Message-ID: <router-nil@example.com>
      Date: Fri, 10 Apr 2026 10:00:00 +0000
      MIME-Version: 1.0
      Content-Type: text/plain; charset=UTF-8

      Nothing to see here.
    EMAIL

    expect(described_class.match(@inbound_email)).to be_nil
  end
end
