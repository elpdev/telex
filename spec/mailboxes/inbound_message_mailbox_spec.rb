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

  it "creates a message for a dot addressed recipient" do
    source = <<~EMAIL
      From: Shop <shop@example.com>
      To: receipts.amazon@lbp.dev
      Subject: Your receipt
      Message-ID: <mailbox-dot-subaddressed@example.com>
      Date: Fri, 10 Apr 2026 11:00:00 +0000
      MIME-Version: 1.0
      Content-Type: text/plain; charset=UTF-8

      Receipt body for Amazon.
    EMAIL

    expect {
      receive_inbound_email_from_source(source)
    }.to change(Message, :count).by(1)
      .and have_enqueued_job(ProcessMessageJob)

    message = Message.last
    expect(message.inbox).to eq(inbox)
    expect(message.subaddress).to eq("amazon")
  end
end
