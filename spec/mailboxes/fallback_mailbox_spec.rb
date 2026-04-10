require "rails_helper"

RSpec.describe FallbackMailbox, type: :mailbox do
  it "quietly accepts unknown addresses" do
    source = <<~EMAIL
      From: Sender <sender@example.com>
      To: nobody@lbp.dev
      Subject: Unknown
      Message-ID: <fallback@example.com>
      Date: Fri, 10 Apr 2026 10:00:00 +0000
      MIME-Version: 1.0
      Content-Type: text/plain; charset=UTF-8

      Nobody home.
    EMAIL

    expect { receive_inbound_email_from_source(source) }.not_to raise_error
  end
end
