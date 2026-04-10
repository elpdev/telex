require "rails_helper"

RSpec.describe InboundMessageMailbox, type: :mailbox do
  let(:domain) { create(:domain, name: "lbp.dev") }
  let!(:inbox) { create(:inbox, domain: domain, local_part: "receipts", pipeline_key: "receipts") }

  it "creates a message and enqueues processing" do
    expect {
      receive_inbound_email_from_source(Rails.root.join("spec/fixtures/files/inbound/subaddressed.eml").read)
    }.to change(Message, :count).by(1)
      .and have_enqueued_job(ProcessMessageJob)

    message = Message.last
    expect(message.inbox).to eq(inbox)
    expect(message.subaddress).to eq("amazon")
  end
end
