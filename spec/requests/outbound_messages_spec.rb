require "rails_helper"

RSpec.describe "OutboundMessages", type: :request do
  describe "POST /outbound_messages" do
    it "creates a new compose draft in the inbox UI" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "support")
      message = create(:message, inbox: inbox)

      expect {
        post outbound_messages_path, params: {inbox_id: inbox.id, message_id: message.id}
      }.to change(OutboundMessage, :count).by(1)

      outbound_message = OutboundMessage.last
      expect(response).to redirect_to(root_path(inbox_id: inbox.id, message_id: message.id, outbound_message_id: outbound_message.id))
      expect(outbound_message.metadata).to include("draft_kind" => "compose")
      expect(outbound_message.domain).to eq(inbox.domain)
      expect(outbound_message.user).to eq(user)
    end
  end

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
      expect(response).to redirect_to(root_path(inbox_id: message.inbox_id, message_id: message.id, outbound_message_id: outbound_message.id))
      expect(outbound_message.source_message).to eq(message)
      expect(outbound_message.to_addresses).to eq(["sender@example.com"])
      expect(outbound_message.user).to eq(user)
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
      expect(outbound_message.user).to eq(user)
    end
  end

  describe "POST /messages/:id/forward" do
    it "creates a forward draft with copied attachments and original context" do
      user = create(:user)
      login_user(user)
      message = create(:message)
      message.attachments.attach(
        io: StringIO.new("attachment data"),
        filename: "invoice.pdf",
        content_type: "application/pdf"
      )

      expect {
        post forward_message_path(message)
      }.to change(OutboundMessage, :count).by(1)

      outbound_message = OutboundMessage.last
      expect(response).to redirect_to(root_path(inbox_id: message.inbox_id, message_id: message.id, outbound_message_id: outbound_message.id))
      expect(outbound_message.metadata).to include("draft_kind" => "forward")
      expect(outbound_message.attachments.map(&:filename).map(&:to_s)).to include("invoice.pdf")
      expect(outbound_message.body.to_plain_text).to include("Forwarded message")
      expect(outbound_message.user).to eq(user)
    end
  end

  describe "PATCH /outbound_messages/:id" do
    it "queues an outbound message for delivery" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: user)

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

    it "re-renders the inbox compose pane when send validation fails" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: user)

      patch outbound_message_path(outbound_message), params: {
        inbox_id: outbound_message.source_message.inbox_id,
        message_id: outbound_message.source_message.id,
        outbound_message: {
          to_addresses: "",
          cc_addresses: "",
          bcc_addresses: "",
          subject: "Updated reply",
          body: "<div>Updated body</div>"
        },
        send_now: "1"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Compose")
      expect(response.body).to include("To addresses can&#39;t be blank")
    end

    it "autosaves draft fields and attachments without queueing delivery" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: user)

      expect {
        patch outbound_message_path(outbound_message), params: {
          autosave: "1",
          outbound_message: {
            to_addresses: "recipient@example.com, another@example.com",
            cc_addresses: "copy@example.com",
            bcc_addresses: "blind@example.com",
            subject: "Autosaved reply",
            body: "<div>Autosaved body</div>",
            attachments: [fixture_file_upload("upload.txt", "text/plain")]
          }
        }
      }.not_to have_enqueued_job(DeliverOutboundMessageJob)

      outbound_message.reload
      expect(response).to have_http_status(:no_content)
      expect(outbound_message).to be_draft
      expect(outbound_message.to_addresses).to eq(["recipient@example.com", "another@example.com"])
      expect(outbound_message.cc_addresses).to eq(["copy@example.com"])
      expect(outbound_message.bcc_addresses).to eq(["blind@example.com"])
      expect(outbound_message.subject).to eq("Autosaved reply")
      expect(outbound_message.body.to_plain_text).to include("Autosaved body")
      expect(outbound_message.attachments.map { |attachment| attachment.filename.to_s }).to include("upload.txt")
    end

    it "does not allow updating another user's draft" do
      user = create(:user)
      other_user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: other_user)

      patch outbound_message_path(outbound_message), params: {
        autosave: "1",
        outbound_message: {
          subject: "Nope",
          to_addresses: "recipient@example.com"
        }
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /outbound_messages/:id" do
    it "destroys the user's draft and redirects to the drafts mailbox" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: user, status: :draft)

      expect {
        delete outbound_message_path(outbound_message)
      }.to change(OutboundMessage, :count).by(-1)

      expect(response).to redirect_to(root_path(mailbox: "drafts"))
    end

    it "returns 404 when destroying another user's draft" do
      user = create(:user)
      other_user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: other_user, status: :draft)

      expect {
        delete outbound_message_path(outbound_message)
      }.not_to change(OutboundMessage, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "refuses to destroy a non-draft outbound message" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: user, status: :sent, sent_at: Time.current)

      expect {
        delete outbound_message_path(outbound_message)
      }.not_to change(OutboundMessage, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
