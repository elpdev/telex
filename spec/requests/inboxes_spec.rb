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
      outbound_message = create(:outbound_message, user: user, source_message: message, domain: inbox.domain)

      get root_path, params: {inbox_id: inbox.id, message_id: message.id, outbound_message_id: outbound_message.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Compose")
      expect(response.body).to include("From")
      expect(response.body).to include("InboxOS &lt;hello@domain.test&gt;")
      expect(response.body).to include("Sending from leo@domain.test")
      expect(response.body).to include("Send reply")
      expect(response.body).to include(message.subject)
    end

    it "hides inbox and message columns while replying" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      message = create(:message, inbox: inbox, subject: "Welcome")
      outbound_message = create(:outbound_message, user: user, source_message: message, domain: inbox.domain)

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
      outbound_message = create(:outbound_message, user: user, domain: inbox.domain, source_message: nil, metadata: {"draft_kind" => "compose"})

      get root_path, params: {inbox_id: inbox.id, outbound_message_id: outbound_message.id}

      expect(response.body).to include("Compose")
      expect(response.body).to include("New message")
      expect(response.body).to include("Sending from domain.test")
      expect(response.body).to include("Drafts")
      expect(response.body).not_to include("Reading pane")
    end

    it "shows mailbox navigation and labels" do
      user = create(:user)
      login_user(user)
      create(:label, user: user, name: "Important")

      get root_path

      expect(response.body).to include("Mailboxes")
      expect(response.body).to include("Archived")
      expect(response.body).to include("Trash")
      expect(response.body).to include("Sent")
      expect(response.body).to include("Important")
    end

    it "filters messages by mailbox state" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      archived_message = create(:message, inbox: inbox, subject: "Archived message")
      inbox_message = create(:message, inbox: inbox, subject: "Inbox message")
      archived_message.move_to_state_for(user, :archived)
      inbox_message.move_to_state_for(user, :inbox)

      get root_path, params: {mailbox: "archived"}

      expect(response.body).to include("Archived message")
      expect(response.body).not_to include("Inbox message")
    end

    it "filters messages by assigned label" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      label = create(:label, user: user, name: "Receipts")
      labeled_message = create(:message, inbox: inbox, subject: "Receipt")
      create(:message, inbox: inbox, subject: "Plain note")
      labeled_message.assign_labels_for(user, [label.id])

      get root_path, params: {label_id: label.id}

      expect(response.body).to include("Receipt")
      expect(response.body).not_to include("Plain note")
    end

    it "archives a message for the current user" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      message = create(:message, inbox: inbox)

      post archive_message_path(message)

      expect(response).to redirect_to(root_path(mailbox: :archived))
      expect(message.reload.effective_system_state_for(user)).to eq("archived")
    end

    it "updates conversation labels from the reading pane flow" do
      user = create(:user)
      login_user(user)
      label = create(:label, user: user, name: "Team")
      message = create(:message)
      conversation = message.conversation || create(:conversation)
      message.update!(conversation: conversation)

      patch labels_conversation_path(conversation), params: {label_ids: [label.id]}

      expect(response).to redirect_to(root_path)
      expect(conversation.reload.labels_for(user).map(&:name)).to eq(["Team"])
    end

    it "shows sent messages in the sent mailbox" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: user, status: :sent, sent_at: Time.current, metadata: {"draft_kind" => "compose"})

      get root_path, params: {mailbox: "sent"}

      expect(response.body).to include("Sent mail")
      expect(response.body).to include(outbound_message.subject)
    end

    it "shows a send warning when the draft domain is not outbound ready" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, name: "broken.test"), local_part: "leo")
      outbound_message = create(:outbound_message, user: user, domain: inbox.domain, source_message: nil, metadata: {"draft_kind" => "compose"})

      get root_path, params: {inbox_id: inbox.id, outbound_message_id: outbound_message.id}

      expect(response.body).to include("Send unavailable")
      expect(response.body).to include("broken.test is not ready to send")
      expect(response.body).to include("disabled=\"disabled\"")
    end

    it "shows only the current user's drafts in the sidebar" do
      user = create(:user)
      other_user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      create(:outbound_message, user: user, domain: inbox.domain, source_message: nil, subject: "My saved draft", metadata: {"draft_kind" => "compose"})
      create(:outbound_message, user: other_user, domain: inbox.domain, source_message: nil, subject: "Someone else's draft", metadata: {"draft_kind" => "compose"})

      get root_path

      expect(response.body).to include("Drafts")
      expect(response.body).to include("My saved draft")
      expect(response.body).not_to include("Someone else&#39;s draft")
    end

    it "does not open another user's draft from the inbox UI" do
      user = create(:user)
      other_user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      outbound_message = create(:outbound_message, user: other_user, domain: inbox.domain, source_message: nil, subject: "Private draft", metadata: {"draft_kind" => "compose"})

      get root_path, params: {inbox_id: inbox.id, outbound_message_id: outbound_message.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Inboxes")
      expect(response.body).not_to include("Private draft")
      expect(response.body).not_to include("Sending from domain.test")
    end
  end
end
