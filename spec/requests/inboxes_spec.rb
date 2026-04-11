require "rails_helper"

RSpec.describe "Inboxes", type: :request do
  describe "GET /" do
    it "redirects signed out users to login" do
      get root_path

      expect(response).to redirect_to(new_session_path)
    end

    it "renders the inbox UI for authenticated users" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      message = create(:message, inbox: inbox, subject: "Welcome to InboxOS")

      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Inboxes")
      expect(response.body).to include("All inboxes")
      expect(response.body).to include(message.subject)
    end

    it "filters messages by inbox" do
      user = create(:user)
      login_user(user)
      selected_inbox = create(:inbox, local_part: "leo")
      other_inbox = create(:inbox, local_part: "receipts")
      create(:message, inbox: selected_inbox, subject: "Leo message")
      create(:message, inbox: other_inbox, subject: "Receipts message")

      get root_path, params: {inbox_id: selected_inbox.id}

      expect(response.body).to include("Leo message")
      expect(response.body).not_to include("Receipts message")
    end

    it "filters messages by search query" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      create(:message, inbox: inbox, subject: "Amazon order")
      create(:message, inbox: inbox, subject: "Family plans")

      get root_path, params: {q: {subject_or_from_address_or_from_name_or_text_body_cont: "Amazon"}}

      expect(response.body).to include("Amazon order")
      expect(response.body).not_to include("Family plans")
    end

    it "filters messages by status" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      create(:message, inbox: inbox, subject: "Processed message", status: :processed)
      create(:message, inbox: inbox, subject: "Failed message", status: :failed)

      get root_path, params: {q: {status_eq: "failed"}}

      expect(response.body).to include("Failed message")
      expect(response.body).not_to include("Processed message")
    end

    it "filters messages by subaddress" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      create(:message, inbox: inbox, subject: "Amazon receipt", subaddress: "amazon")
      create(:message, inbox: inbox, subject: "Family update", subaddress: "family")

      get root_path, params: {q: {subaddress_cont: "amaz"}}

      expect(response.body).to include("Amazon receipt")
      expect(response.body).not_to include("Family update")
    end

    it "searches by sender email in the main search field" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      create(:message, inbox: inbox, subject: "Message from Bee", from_address: "b@example.com")
      create(:message, inbox: inbox, subject: "Message from Ay", from_address: "a@example.com")

      get root_path, params: {q: {subject_or_from_address_or_from_name_or_text_body_cont: "b@example.com"}}

      expect(response.body).to include("Message from Bee")
      expect(response.body).not_to include("Message from Ay")
    end

    it "shows the selected message in the reading pane" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      older_message = create(:message, inbox: inbox, subject: "Older")
      selected_message = create(:message, inbox: inbox, subject: "Selected", subaddress: "tag")
      selected_message.body = "<p>Rendered body</p>"
      selected_message.save!

      get root_path, params: {message_id: selected_message.id}

      expect(response.body).to include("Selected")
      expect(response.body).to include("Rendered body")
      expect(response.body).to include("+tag")
      expect(response.body).to include(selected_message.inbox.address)
      expect(response.body).to include(older_message.subject)
    end

    it "shows thread history for related inbound and outbound messages" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      root_message = create(:message, inbox: inbox, subject: "Thread root", from_address: "sender@example.com")
      reply = Outbound::ReplyBuilder.create!(root_message)
      reply.update!(status: :sent, sent_at: Time.current, mail_message_id: "<reply@example.com>")

      get root_path, params: {message_id: root_message.id}

      expect(response.body).to include("Thread history")
      expect(response.body).to include("Inbound")
      expect(response.body).to include("Outbound")
      expect(response.body).to include("Thread root")
    end

    it "renders the compose pane inside the inbox UI when a draft is selected" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      message = create(:message, inbox: inbox, subject: "Welcome")
      outbound_message = create(:outbound_message, source_message: message, domain: inbox.domain)

      get root_path, params: {inbox_id: inbox.id, message_id: message.id, outbound_message_id: outbound_message.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Compose")
      expect(response.body).to include("Send reply")
      expect(response.body).to include(message.subject)
    end

    it "hides inbox and message columns while replying" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      message = create(:message, inbox: inbox, subject: "Welcome")
      outbound_message = create(:outbound_message, source_message: message, domain: inbox.domain)

      get root_path, params: {inbox_id: inbox.id, message_id: message.id, outbound_message_id: outbound_message.id}

      expect(response.body).to include("Reading pane")
      expect(response.body).to include("Compose")
      expect(response.body).not_to include("Inboxes")
      expect(response.body).not_to include("Messages")
    end

    it "shows only the compose pane for a brand new draft" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      outbound_message = create(:outbound_message, domain: inbox.domain, source_message: nil, metadata: {"draft_kind" => "compose"})

      get root_path, params: {inbox_id: inbox.id, outbound_message_id: outbound_message.id}

      expect(response.body).to include("Compose")
      expect(response.body).to include("New message")
      expect(response.body).not_to include("Inboxes")
      expect(response.body).not_to include("Messages")
      expect(response.body).not_to include("Reading pane")
    end
  end
end
