require "rails_helper"

RSpec.describe Outbound::AutoForwarder do
  describe ".forward_matching!" do
    it "creates and enqueues forwarded messages for matching rules" do
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), forwarding_rules: [{
        "name" => "Relay receipts",
        "from_address_pattern" => "amazon",
        "target_addresses" => ["ops@example.com"]
      }])
      message = create(:message, inbox: inbox, from_address: "shipping@amazon.com")

      expect {
        described_class.forward_matching!(message)
      }.to change(OutboundMessage, :count).by(1)
        .and have_enqueued_job(DeliverOutboundMessageJob)

      outbound_message = OutboundMessage.last
      expect(outbound_message).to be_queued
      expect(outbound_message.to_addresses).to eq(["ops@example.com"])
      expect(outbound_message.metadata).to include("automatic_forward" => true, "forwarding_rule_name" => "Relay receipts")
    end

    it "ignores non-matching rules" do
      inbox = create(:inbox, forwarding_rules: [{"subject_pattern" => "invoice", "target_addresses" => ["ops@example.com"]}])
      message = create(:message, inbox: inbox, subject: "Family update")

      expect {
        described_class.forward_matching!(message)
      }.not_to change(OutboundMessage, :count)
    end
  end
end
