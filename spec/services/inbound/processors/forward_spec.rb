require "rails_helper"

RSpec.describe Inbound::Processors::Forward do
  it "records forwarded message ids in pipeline metadata" do
    inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), forwarding_rules: [{"from_address_pattern" => "amazon", "target_addresses" => ["ops@example.com"]}])
    message = create(:message, inbox: inbox, from_address: "shipping@amazon.com")
    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: inbox,
      message: message,
      subaddress: message.subaddress,
      metadata: {}
    )

    described_class.call(context)

    expect(context.metadata["forwarded_message_ids"]).to eq([OutboundMessage.last.id])
  end
end
