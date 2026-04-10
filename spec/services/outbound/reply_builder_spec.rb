require "rails_helper"

RSpec.describe Outbound::ReplyBuilder do
  describe ".create!" do
    it "builds a reply draft with sender, subject, and thread headers" do
      inbound_email = create(:action_mailbox_inbound_email, source: <<~EMAIL)
        From: Sender <sender@example.com>
        To: support@domain.test
        Subject: Original subject
        Message-ID: <factory-reply@example.com>
        References: <older@example.com>
        Date: Fri, 10 Apr 2026 10:00:00 +0000
        MIME-Version: 1.0
        Content-Type: text/plain; charset=UTF-8

        Original body.
      EMAIL
      message = create(
        :message,
        inbox: create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "support"),
        inbound_email: inbound_email,
        from_address: "sender@example.com",
        subject: "Original subject",
        message_id: "factory-reply@example.com",
        to_addresses: ["support@domain.test"]
      )

      outbound_message = described_class.create!(message)

      expect(outbound_message.domain).to eq(message.inbox.domain)
      expect(outbound_message.source_message).to eq(message)
      expect(outbound_message.to_addresses).to eq(["sender@example.com"])
      expect(outbound_message.subject).to eq("Re: Original subject")
      expect(outbound_message.in_reply_to_message_id).to eq("<factory-reply@example.com>")
      expect(outbound_message.reference_message_ids).to eq(["<older@example.com>", "<factory-reply@example.com>"])
    end

    it "excludes the current inbox address on reply-all" do
      message = create(
        :message,
        inbox: create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "support"),
        from_address: "sender@example.com",
        to_addresses: ["support@domain.test", "teammate@example.com"],
        cc_addresses: ["support@domain.test", "manager@example.com"]
      )

      outbound_message = described_class.create!(message, reply_all: true)

      expect(outbound_message.to_addresses).to eq(["sender@example.com", "teammate@example.com"])
      expect(outbound_message.cc_addresses).to eq(["manager@example.com"])
      expect(outbound_message.metadata).to include("reply_all" => true)
    end
  end
end
