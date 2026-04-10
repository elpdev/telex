require "rails_helper"

RSpec.describe Outbound::ForwardBuilder do
  describe ".create!" do
    it "builds a forward draft with original context and attachments" do
      message = create(:message, subject: "Monthly report", from_name: "Sender", from_address: "sender@example.com")
      message.attachments.attach(
        io: StringIO.new("attachment data"),
        filename: "report.txt",
        content_type: "text/plain"
      )

      outbound_message = described_class.create!(message, target_addresses: ["team@example.com"], rule_name: "Team relay")

      expect(outbound_message.to_addresses).to eq(["team@example.com"])
      expect(outbound_message.subject).to eq("Fwd: Monthly report")
      expect(outbound_message.metadata).to include("draft_kind" => "forward", "forwarding_rule_name" => "Team relay", "automatic_forward" => false)
      expect(outbound_message.body.to_plain_text).to include("Forwarded message")
      expect(outbound_message.body.to_plain_text).to include("From: Sender (sender@example.com)")
      expect(outbound_message.body.to_plain_text).to include("Monthly report")
      expect(outbound_message.attachments.map(&:filename).map(&:to_s)).to include("report.txt")
    end
  end
end
