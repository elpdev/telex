require "rails_helper"

RSpec.describe Conversations::Resolver do
  describe ".assign!" do
    it "keeps outbound replies in the source message conversation" do
      message = create(:message)
      conversation = described_class.assign!(message)
      outbound_message = create(:outbound_message, source_message: message, metadata: {"reply_all" => false})

      described_class.assign!(outbound_message)

      expect(outbound_message.reload.conversation).to eq(conversation)
    end

    it "matches inbound follow-ups by outbound mail headers" do
      original = create(:message, message_id: "<original@example.com>")
      conversation = described_class.assign!(original)
      outbound_message = create(
        :outbound_message,
        source_message: original,
        in_reply_to_message_id: "<original@example.com>",
        reference_message_ids: ["<original@example.com>"],
        mail_message_id: "<sent@example.com>"
      )
      described_class.assign!(outbound_message)

      inbound_email = create(:action_mailbox_inbound_email, source: <<~EMAIL)
        From: Sender <sender@example.com>
        To: #{original.inbox.address}
        Subject: Re: #{original.subject}
        Message-ID: <followup@example.com>
        In-Reply-To: <sent@example.com>
        References: <original@example.com> <sent@example.com>
        Date: Fri, 10 Apr 2026 10:00:00 +0000
        MIME-Version: 1.0
        Content-Type: text/plain; charset=UTF-8

        Follow up body.
      EMAIL
      follow_up = create(:message, inbox: original.inbox, inbound_email: inbound_email, message_id: "<followup@example.com>", subject: "Re: #{original.subject}")

      described_class.assign!(follow_up)

      expect(follow_up.reload.conversation).to eq(conversation)
    end

    it "falls back to normalized subject and participants when headers are missing" do
      first = create(:message, subject: "Project update", from_address: "sender@example.com", to_addresses: ["team@example.com"])
      conversation = described_class.assign!(first)
      second = create(:message, inbox: first.inbox, subject: "Re: Project update", from_address: "team@example.com", to_addresses: ["sender@example.com"])

      described_class.assign!(second)

      expect(second.reload.conversation).to eq(conversation)
    end
  end
end
