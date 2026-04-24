require "rails_helper"

RSpec.describe Outbound::Sender do
  describe ".deliver!" do
    it "delivers through the domain configuration and marks the message sent" do
      outbound_message = create(:outbound_message)

      delivered_message = described_class.deliver!(outbound_message)

      expect(delivered_message.to).to eq(["recipient@example.com"])
      expect(delivered_message.from).to eq(["hello@#{outbound_message.domain.name}"])
      expect(delivered_message.reply_to).to eq(["hello@#{outbound_message.domain.name}"])
      expect(delivered_message.subject).to eq("Outbound subject")
      expect(outbound_message.reload).to be_sent
      expect(outbound_message.mail_message_id).to eq(delivered_message.message_id)
      expect(outbound_message.sent_at).to be_present
    end

    it "uses the selected inbox as the from address" do
      domain = create(:domain, :with_outbound_configuration, name: "domain.test")
      inbox = create(:inbox, domain: domain, local_part: "support")
      outbound_message = create(:outbound_message, domain: domain, inbox: inbox)

      delivered_message = described_class.deliver!(outbound_message)

      expect(delivered_message.from).to eq(["support@domain.test"])
    end

    it "delivers attachments" do
      outbound_message = create(:outbound_message)
      outbound_message.attachments.attach(
        io: StringIO.new("attachment body"),
        filename: "hello.txt",
        content_type: "text/plain"
      )

      delivered_message = described_class.deliver!(outbound_message)

      expect(delivered_message.attachments.map(&:filename).map(&:to_s)).to include("hello.txt")
      expect(delivered_message.attachments.first.body.decoded).to eq("attachment body")
    end

    it "sets reply threading headers" do
      outbound_message = create(
        :outbound_message,
        in_reply_to_message_id: "<original@example.com>",
        reference_message_ids: ["<older@example.com>", "<original@example.com>"]
      )

      delivered_message = described_class.deliver!(outbound_message)

      expect(delivered_message.header["In-Reply-To"].to_s).to include("<original@example.com>")
      expect(delivered_message.header["References"].to_s).to include("<older@example.com> <original@example.com>")
    end

    it "raises when no recipients are present" do
      outbound_message = create(:outbound_message, to_addresses: [])

      expect {
        described_class.deliver!(outbound_message)
      }.to raise_error(Outbound::DeliveryError, /at least one recipient/)
    end
  end
end
