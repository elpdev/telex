require "rails_helper"

RSpec.describe ApplicationMailbox, type: :mailbox do
  let(:domain) { create(:domain, name: "lbp.dev") }

  before do
    create(:inbox, domain: domain, local_part: "home")
  end

  it "routes matching mail to the inbound mailbox" do
    expect {
      receive_inbound_email_from_source(Rails.root.join("spec/fixtures/files/inbound/plain_text.eml").read)
    }.to have_enqueued_job(ProcessMessageJob)
  end

  it "routes unknown mail to the fallback mailbox without raising" do
    source = <<~EMAIL
      From: Sender <sender@example.com>
      To: nobody@lbp.dev
      Subject: Unknown
      Message-ID: <unknown-mailbox@example.com>
      Date: Fri, 10 Apr 2026 10:00:00 +0000
      MIME-Version: 1.0
      Content-Type: text/plain; charset=UTF-8

      Nobody home.
    EMAIL

    expect { receive_inbound_email_from_source(source) }.not_to raise_error
  end
end
