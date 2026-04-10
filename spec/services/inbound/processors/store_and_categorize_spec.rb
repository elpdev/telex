require "rails_helper"

RSpec.describe Inbound::Processors::StoreAndCategorize do
  it "adds tags based on the message state" do
    message = create(:message, subaddress: "amazon", from_address: "owner@#{create(:domain, name: "lbp.dev").name}")
    message.attachments.attach(io: StringIO.new("data"), filename: "file.txt", content_type: "text/plain")
    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: create(:inbox, domain: create(:domain, name: "mail.test")),
      message: message,
      subaddress: "amazon",
      metadata: {}
    )

    described_class.call(context)

    expect(context.metadata["tags"]).to include("has_attachments", "subaddressed")
  end
end
