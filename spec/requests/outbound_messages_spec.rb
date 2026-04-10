require "rails_helper"

RSpec.describe "OutboundMessages", type: :request do
  describe "POST /messages/:id/reply" do
    it "requires authentication" do
      message = create(:message)

      post reply_message_path(message)

      expect(response).to redirect_to(new_session_path)
    end

    it "creates a reply draft and redirects to edit" do
      user = create(:user)
      login_user(user)
      message = create(:message, inbox: create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "support"), from_address: "sender@example.com")

      expect {
        post reply_message_path(message)
      }.to change(OutboundMessage, :count).by(1)

      outbound_message = OutboundMessage.last
      expect(response).to redirect_to(edit_outbound_message_path(outbound_message))
      expect(outbound_message.source_message).to eq(message)
      expect(outbound_message.to_addresses).to eq(["sender@example.com"])
    end
  end

  describe "POST /messages/:id/reply_all" do
    it "excludes the current inbox address from recipients" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "support")
      message = create(:message, inbox: inbox, from_address: "sender@example.com", to_addresses: [inbox.address, "person@example.com"], cc_addresses: [inbox.address, "team@example.com"])

      post reply_all_message_path(message)

      outbound_message = OutboundMessage.last
      expect(outbound_message.to_addresses).to eq(["sender@example.com", "person@example.com"])
      expect(outbound_message.cc_addresses).to eq(["team@example.com"])
    end
  end

  describe "PATCH /outbound_messages/:id" do
    it "queues a reply for delivery" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message)

      expect {
        patch outbound_message_path(outbound_message), params: {
          outbound_message: {
            to_addresses: "recipient@example.com, another@example.com",
            cc_addresses: "copy@example.com",
            bcc_addresses: "blind@example.com",
            subject: "Updated reply",
            body: "<div>Updated body</div>"
          },
          send_now: "1"
        }
      }.to have_enqueued_job(DeliverOutboundMessageJob).with(outbound_message)

      outbound_message.reload
      expect(response).to redirect_to(root_path(inbox_id: outbound_message.source_message&.inbox_id, message_id: outbound_message.source_message&.id))
      expect(outbound_message).to be_queued
      expect(outbound_message.to_addresses).to eq(["recipient@example.com", "another@example.com"])
      expect(outbound_message.cc_addresses).to eq(["copy@example.com"])
      expect(outbound_message.bcc_addresses).to eq(["blind@example.com"])
      expect(outbound_message.subject).to eq("Updated reply")
    end
  end
end
