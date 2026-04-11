require "rails_helper"

RSpec.describe "API::V1::MailboxResources", type: :request do
  let(:user) { create(:user) }
  let(:headers) { api_headers_for(user) }

  describe "authorization" do
    it "rejects unauthenticated access" do
      get "/api/v1/domains"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "domains" do
    it "creates, shows readiness, and validates domains" do
      post "/api/v1/domains", params: {
        domain: {
          name: "agent.test",
          active: true,
          outbound_from_name: "Agent",
          outbound_from_address: "hello@agent.test",
          use_from_address_for_reply_to: true,
          smtp_host: "smtp.agent.test",
          smtp_port: 587,
          smtp_username: "smtp-user",
          smtp_password: "smtp-pass",
          smtp_authentication: "login",
          smtp_enable_starttls_auto: true
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      domain_id = JSON.parse(response.body).dig("data", "id")

      get "/api/v1/domains/#{domain_id}/outbound_status", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "outbound_ready")).to eq(true)

      post "/api/v1/domains/#{domain_id}/validate_outbound", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "valid")).to eq(true)
    end
  end

  describe "inboxes" do
    it "creates inboxes and returns pipeline metadata" do
      domain = create(:domain)

      post "/api/v1/inboxes", params: {
        inbox: {
          domain_id: domain.id,
          local_part: "support",
          pipeline_key: "receipts",
          description: "Support inbox",
          active: true,
          pipeline_overrides: {"notify" => false},
          forwarding_rules: [
            {
              name: "Billing",
              active: true,
              subject_pattern: "invoice",
              target_addresses: ["billing@example.com"]
            }
          ]
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      inbox_id = JSON.parse(response.body).dig("data", "id")

      get "/api/v1/inboxes/#{inbox_id}/pipeline", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "key")).to eq("receipts")

      post "/api/v1/inboxes/#{inbox_id}/test_forwarding_rules", params: {
        inbox: {
          forwarding_rules: [
            {
              name: "Ops",
              active: true,
              target_addresses: ["ops@example.com"]
            }
          ]
        }
      }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "valid")).to eq(true)
    end
  end

  describe "messages and conversations" do
    it "lists messages, exposes bodies and attachments, and shows conversation timeline" do
      domain = create(:domain, :with_outbound_configuration)
      inbox = create(:inbox, domain: domain, local_part: "support")
      conversation = create(:conversation)
      inbound_email = create(:action_mailbox_inbound_email, source: file_fixture("inbound/html_with_attachment.eml").read)
      message = create(:message, inbox: inbox, inbound_email: inbound_email, conversation: conversation, subject: "Invoice update")
      message.body = "<p>Hello agent</p>"
      message.save!

      reply = Outbound::ReplyBuilder.create!(message)
      reply.update!(status: :sent, sent_at: Time.current, mail_message_id: "<reply@example.com>")

      get "/api/v1/messages", params: {inbox_id: inbox.id, q: "Invoice"}, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.dig("data", 0, "subject")).to eq("Invoice update")

      get "/api/v1/messages/#{message.id}/body", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "text")).to be_present

      get "/api/v1/messages/#{message.id}/attachments", headers: headers
      expect(response).to have_http_status(:ok)
      attachment_id = JSON.parse(response.body).dig("data", 0, "id")

      get "/api/v1/messages/#{message.id}/attachments/#{attachment_id}", headers: headers
      expect(response).to have_http_status(:ok)

      get "/api/v1/conversations/#{message.conversation_id}/timeline", headers: headers
      expect(response).to have_http_status(:ok)
      kinds = JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("kind") }
      expect(kinds).to include("inbound", "outbound")
    end

    it "supports message search across body, attachments, sender, recipient, and date range" do
      inbox = create(:inbox, domain: create(:domain), local_part: "support")
      matching_message = create(
        :message,
        inbox: inbox,
        subject: "Invoice update",
        from_name: "Billing Bot",
        from_address: "billing@example.com",
        to_addresses: [inbox.address, "finance@example.com"],
        text_body: "Please review the attached invoice",
        received_at: Time.zone.parse("2026-04-10 10:00:00")
      )
      matching_message.attachments.attach(
        io: StringIO.new("invoice data"),
        filename: "invoice-2026.pdf",
        content_type: "application/pdf"
      )
      create(
        :message,
        inbox: inbox,
        subject: "Family update",
        from_name: "Family",
        from_address: "family@example.com",
        to_addresses: [inbox.address, "home@example.com"],
        text_body: "Weekend plans",
        received_at: Time.zone.parse("2026-04-01 10:00:00")
      )

      get "/api/v1/messages", params: {
        inbox_id: inbox.id,
        q: "invoice-2026.pdf",
        sender: "billing",
        recipient: "finance@example.com",
        received_from: "2026-04-09",
        received_to: "2026-04-10"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.fetch("data").map { |record| record.fetch("id") }).to eq([matching_message.id])
    end

    it "creates reply, reply-all, and forward drafts from inbound messages" do
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "support")
      message = create(:message, inbox: inbox, from_address: "sender@example.com", to_addresses: [inbox.address, "person@example.com"], cc_addresses: ["team@example.com"])

      post "/api/v1/messages/#{message.id}/reply", headers: headers
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body).dig("data", "to_addresses")).to eq(["sender@example.com"])

      post "/api/v1/messages/#{message.id}/reply_all", headers: headers
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body).dig("data", "cc_addresses")).to eq(["team@example.com"])

      post "/api/v1/messages/#{message.id}/forward", params: {target_addresses: ["archive@example.com"]}, headers: headers
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body).dig("data", "to_addresses")).to eq(["archive@example.com"])
    end
  end

  describe "outbound messages" do
    it "creates, updates, sends, and manages attachments for outbound drafts" do
      domain = create(:domain, :with_outbound_configuration)

      post "/api/v1/outbound_messages", params: {
        outbound_message: {
          domain_id: domain.id,
          to_addresses: ["person@example.com"],
          subject: "Initial",
          body: "<p>Hello</p>",
          metadata: {"draft_kind" => "compose"}
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      outbound_message_id = JSON.parse(response.body).dig("data", "id")

      patch "/api/v1/outbound_messages/#{outbound_message_id}", params: {
        outbound_message: {
          to_addresses: ["recipient@example.com", "another@example.com"],
          cc_addresses: ["copy@example.com"],
          subject: "Updated",
          body: "<div>Updated body</div>"
        }
      }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "subject")).to eq("Updated")

      file = fixture_file_upload("upload.txt", "text/plain")
      post "/api/v1/outbound_messages/#{outbound_message_id}/attachments", params: {file: file}, headers: headers
      expect(response).to have_http_status(:created)
      attachment_id = JSON.parse(response.body).dig("data", 0, "id")

      post "/api/v1/outbound_messages/#{outbound_message_id}/send_message", headers: headers
      expect(response).to have_http_status(:ok)
      expect(OutboundMessage.find(outbound_message_id)).to be_queued

      delete "/api/v1/outbound_messages/#{outbound_message_id}/attachments/#{attachment_id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end
  end
end
