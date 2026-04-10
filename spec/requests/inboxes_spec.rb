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
      expect(response.body).to include("Programmable Inbox")
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

      get root_path, params: {q: {subaddress_eq: "amazon"}}

      expect(response.body).to include("Amazon receipt")
      expect(response.body).not_to include("Family update")
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
  end
end
