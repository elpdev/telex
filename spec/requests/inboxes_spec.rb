require "rails_helper"

RSpec.describe "Inboxes", type: :request do
  describe "GET /domains/:domain_id/inboxes/new" do
    it "renders the nested inbox form" do
      user = create(:user)
      login_user(user)
      domain = create(:domain, name: "example.test")

      get new_domain_inbox_path(domain)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("NEW INBOX")
      expect(response.body).to include(domain.name)
    end
  end

  describe "POST /domains/:domain_id/inboxes" do
    it "creates an inbox for the domain" do
      user = create(:user)
      login_user(user)
      domain = create(:domain, name: "example.test")

      expect {
        post domain_inboxes_path(domain), params: {
          inbox: {
            local_part: "support",
            pipeline_key: "default",
            description: "Main support queue",
            active: "1",
            pipeline_overrides: JSON.generate({"notify" => true}),
            forwarding_rules: JSON.generate([
              {"name" => "vip", "target_addresses" => ["ops@example.test"]}
            ])
          }
        }
      }.to change(domain.inboxes, :count).by(1)

      inbox = domain.inboxes.order(:id).last
      expect(inbox.address).to eq("support@example.test")
      expect(inbox.pipeline_overrides).to eq({"notify" => true})
      expect(inbox.forwarding_rules.first["name"]).to eq("vip")
      expect(response).to redirect_to(domain_path(domain))
    end

    it "re-renders when json is invalid" do
      user = create(:user)
      login_user(user)
      domain = create(:domain, name: "example.test")

      post domain_inboxes_path(domain), params: {
        inbox: {
          local_part: "support",
          pipeline_key: "default",
          pipeline_overrides: "{bad json",
          forwarding_rules: "[]"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("blocked save")
      expect(response.body).to include("Pipeline overrides")
    end
  end

  describe "PATCH /domains/:domain_id/inboxes/:id" do
    it "updates a domain inbox" do
      user = create(:user)
      login_user(user)
      domain = create(:domain, name: "example.test")
      inbox = create(:inbox, domain: domain, local_part: "support", description: "Old")

      patch domain_inbox_path(domain, inbox), params: {
        inbox: {
          local_part: "help",
          pipeline_key: "receipts",
          description: "Updated",
          active: "0",
          pipeline_overrides: "{}",
          forwarding_rules: "[]"
        }
      }

      expect(response).to redirect_to(domain_path(domain))
      expect(inbox.reload.address).to eq("help@example.test")
      expect(inbox.pipeline_key).to eq("receipts")
      expect(inbox.description).to eq("Updated")
      expect(inbox).not_to be_active
    end
  end

  describe "DELETE /domains/:domain_id/inboxes/:id" do
    it "deletes the domain inbox" do
      user = create(:user)
      login_user(user)
      domain = create(:domain)
      inbox = create(:inbox, domain: domain)

      expect {
        delete domain_inbox_path(domain, inbox)
      }.to change(domain.inboxes, :count).by(-1)

      expect(response).to redirect_to(domain_path(domain))
    end
  end

  describe "GET /" do
    it "redirects signed out users to the welcome/landing page" do
      get root_path

      expect(response).to redirect_to(welcome_path)
    end

    it "renders the inbox UI for authenticated users" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      message = create(:message, inbox: inbox, subject: "Welcome to Telex")

      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("[INBOX]")
      expect(response.body).to include(message.subject)
      expect(response.body).to include("Telex")
    end

    it "renders invitation actions for calendar invite messages" do
      user = create(:user, email_address: "leo@example.com")
      login_user(user)
      inbox = create(:inbox, local_part: "inbox")
      inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(
        build_calendar_invitation_email(to: inbox.address, attendee_email: user.email_address)
      )
      message = Inbound::Ingestor.ingest!(inbound_email, inbox: inbox)
      ProcessMessageJob.perform_now(message)

      get root_path, params: {message_id: message.id, inbox_id: inbox.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to include("calendar invitation")
      expect(response.body).to include("[ accept ]")
      expect(response.body).to include("[ OPEN EVENT ]")
    end

    it "updates the local RSVP state for an invitation" do
      user = create(:user, email_address: "leo@example.com")
      login_user(user)
      inbox = create(:inbox, local_part: "inbox")
      inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(
        build_calendar_invitation_email(to: inbox.address, attendee_email: user.email_address)
      )
      message = Inbound::Ingestor.ingest!(inbound_email, inbox: inbox)
      ProcessMessageJob.perform_now(message)

      patch invitation_message_path(message), params: {invitation: {participation_status: "accepted"}}

      expect(response).to redirect_to(root_path(inbox_id: inbox.id, message_id: message.id))
      event = user.calendars.first.calendar_events.find_by(uid: "invite-1")
      expect(event.calendar_event_attendees.find_by(email: user.email_address)).to be_accepted
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

      get root_path, params: {q: {query: "Amazon"}}

      expect(response.body).to include("Amazon order")
      expect(response.body).not_to include("Family plans")
    end

    it "filters messages by status" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      create(:message, inbox: inbox, subject: "Processed message", status: :processed)
      create(:message, inbox: inbox, subject: "Failed message", status: :failed)

      get root_path, params: {q: {status: "failed"}}

      expect(response.body).to include("Failed message")
      expect(response.body).not_to include("Processed message")
    end

    it "filters messages by subaddress" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      create(:message, inbox: inbox, subject: "Amazon receipt", subaddress: "amazon")
      create(:message, inbox: inbox, subject: "Family update", subaddress: "family")

      get root_path, params: {q: {subaddress: "amaz"}}

      expect(response.body).to include("Amazon receipt")
      expect(response.body).not_to include("Family update")
    end

    it "renders pagination controls without raising on later pages" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")

      19.times do |index|
        create(:message, inbox: inbox, subject: "Paged message #{index}")
      end

      get root_path, params: {page: 2}

      expect(response).to have_http_status(:success)
      expect(response.body).to include("page 2 / 2")
      expect(response.body).to include("page=1")
      expect(response.body).not_to include("page=3")
    end

    it "searches by sender email in the main search field" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      create(:message, inbox: inbox, subject: "Message from Bee", from_address: "b@example.com")
      create(:message, inbox: inbox, subject: "Message from Ay", from_address: "a@example.com")

      get root_path, params: {q: {query: "b@example.com"}}

      expect(response.body).to include("Message from Bee")
      expect(response.body).not_to include("Message from Ay")
    end

    it "searches by attachment filename" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      matching_message = create(:message, inbox: inbox, subject: "Quarterly update")
      other_message = create(:message, inbox: inbox, subject: "Family update")

      matching_message.attachments.attach(
        io: StringIO.new("spreadsheet"),
        filename: "quarterly-report.pdf",
        content_type: "application/pdf"
      )

      get root_path, params: {q: {query: "quarterly-report.pdf"}}

      expect(response.body).to include("Quarterly update")
      expect(response.body).not_to include(other_message.subject)
    end

    it "filters by sender, recipient, and received date range" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      matching_message = create(
        :message,
        inbox: inbox,
        subject: "Release prep",
        from_address: "alice@example.com",
        to_addresses: [inbox.address, "team@example.com"],
        received_at: Time.zone.parse("2026-04-10 09:00:00")
      )
      create(
        :message,
        inbox: inbox,
        subject: "Old prep",
        from_address: "alice@example.com",
        to_addresses: [inbox.address, "team@example.com"],
        received_at: Time.zone.parse("2026-04-01 09:00:00")
      )
      create(
        :message,
        inbox: inbox,
        subject: "Wrong sender",
        from_address: "bob@example.com",
        to_addresses: [inbox.address, "team@example.com"],
        received_at: Time.zone.parse("2026-04-10 09:00:00")
      )

      get root_path, params: {
        q: {
          sender: "alice@example.com",
          recipient: "team@example.com",
          received_from: "2026-04-09",
          received_to: "2026-04-10"
        }
      }

      expect(response.body).to include(matching_message.subject)
      expect(response.body).not_to include("Old prep")
      expect(response.body).not_to include("Wrong sender")
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

    it "marks the selected message read when opened" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      message = create(:message, inbox: inbox, subject: "Read me")

      get root_path, params: {message_id: message.id}

      expect(message.reload.read_for?(user)).to eq(true)
      expect(response.body).to include("[READ]")
      expect(response.body).to include("unread")
    end

    it "shows unread and starred state in the message list" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      selected_message = create(:message, inbox: inbox, subject: "Selected")
      triaged_message = create(:message, inbox: inbox, subject: "Needs follow up", received_at: 1.minute.ago)

      post mark_unread_message_path(triaged_message), headers: {"HTTP_REFERER" => root_path(message_id: selected_message.id)}
      post star_message_path(triaged_message), headers: {"HTTP_REFERER" => root_path(message_id: selected_message.id)}

      get root_path, params: {message_id: selected_message.id}

      expect(response.body).to include("Needs follow up")
      expect(triaged_message.reload.unread_for?(user)).to eq(true)
      expect(triaged_message.reload.starred_for?(user)).to eq(true)
    end

    it "shows attachment preview and download actions for previewable inbound files" do
      user = create(:user)
      login_user(user)
      message = create(:message, subject: "Invoice")
      message.attachments.attach(
        io: StringIO.new("pdf-data"),
        filename: "invoice.pdf",
        content_type: "application/pdf"
      )

      get root_path, params: {message_id: message.id, attachment_id: message.attachments.first.id}

      expect(response.body).to include("Attachments")
      expect(response.body).to include("invoice.pdf")
      expect(response.body).to include("Preview")
      expect(response.body).to include("Download")
      expect(response.body).to include("Attachment preview")
      expect(response.body).to include(message_attachment_path(message, message.attachments.first))
    end

    it "shows a fallback message for unsupported inbound attachments" do
      user = create(:user)
      login_user(user)
      message = create(:message, subject: "Logs")
      message.attachments.attach(
        io: StringIO.new("log-data"),
        filename: "server.zip",
        content_type: "application/zip"
      )

      get root_path, params: {message_id: message.id}

      expect(response.body).to include("server.zip")
      expect(response.body).to include("Preview unavailable for this file type")
      expect(response.body).to include("Download")
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
      expect(response.body).to include("Telex &lt;hello@domain.test&gt;")
      expect(response.body).to include("Sending from leo@domain.test")
      expect(response.body).to include("Send reply")
      expect(response.body).to include(message.subject)
    end

    it "keeps the feed and thread reader visible while replying inline" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      message = create(:message, inbox: inbox, subject: "Welcome")
      outbound_message = create(:outbound_message, user: user, source_message: message, domain: inbox.domain)

      get root_path, params: {inbox_id: inbox.id, message_id: message.id, outbound_message_id: outbound_message.id}

      expect(response).to have_http_status(:success)
      # Feed column is still present (thread reader is no longer hidden during compose)
      expect(response.body).to include(message.subject)
      # Compose pane is rendered inline
      expect(response.body).to include("Compose")
      expect(response.body).to include("Send reply")
    end

    it "shows the compose pane for a brand new draft with no source message" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      outbound_message = create(:outbound_message, user: user, domain: inbox.domain, source_message: nil, metadata: {"draft_kind" => "compose"})

      get root_path, params: {inbox_id: inbox.id, outbound_message_id: outbound_message.id}

      expect(response.body).to include("Compose")
      expect(response.body).to include("New message")
      expect(response.body).to include("Sending from domain.test")
    end

    it "shows mailbox navigation and labels" do
      user = create(:user)
      login_user(user)
      create(:label, user: user, name: "Important")

      get root_path

      expect(response.body).to include("Archived")
      expect(response.body).to include("Trash")
      expect(response.body).to include("Sent")
      expect(response.body).to include("Important")
    end

    it "shows attachment preview and download actions for sent outbound files" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, :sent, user: user)
      outbound_message.attachments.attach(
        io: StringIO.new("sent-image"),
        filename: "sent.png",
        content_type: "image/png"
      )

      get root_path, params: {mailbox: "sent", sent_message_id: outbound_message.id, sent_attachment_id: outbound_message.attachments.first.id}

      expect(response.body).to include("transmission")
      expect(response.body).to include("sent.png")
      expect(response.body).to include("Preview")
      expect(response.body).to include("Download")
      expect(response.body).to include(outbound_message_attachment_path(outbound_message, outbound_message.attachments.first))
    end

    it "shows attachment preview and download actions in compose" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: user)
      outbound_message.attachments.attach(
        io: StringIO.new("draft-image"),
        filename: "draft.png",
        content_type: "image/png"
      )

      get root_path, params: {outbound_message_id: outbound_message.id, outbound_attachment_id: outbound_message.attachments.first.id}

      expect(response.body).to include("draft.png")
      expect(response.body).to include("Preview")
      expect(response.body).to include("Download")
      expect(response.body).to include(outbound_message_attachment_path(outbound_message, outbound_message.attachments.first))
    end

    it "filters messages by mailbox state" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      archived_message = create(:message, inbox: inbox, subject: "Archived message")
      junk_message = create(:message, inbox: inbox, subject: "Junk message")
      inbox_message = create(:message, inbox: inbox, subject: "Inbox message")
      archived_message.move_to_state_for(user, :archived)
      junk_message.move_to_state_for(user, :junk)
      inbox_message.move_to_state_for(user, :inbox)

      get root_path, params: {mailbox: "archived"}

      expect(response.body).to include("Archived message")
      expect(response.body).not_to include("Inbox message")

      get root_path, params: {mailbox: "junk"}

      expect(response.body).to include("Junk message")
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

    it "updates message read and starred state" do
      user = create(:user)
      login_user(user)
      message = create(:message)

      post mark_read_message_path(message)
      expect(response).to redirect_to(root_path(message_id: message.id))
      expect(message.reload.read_for?(user)).to eq(true)

      post mark_unread_message_path(message)
      expect(response).to redirect_to(root_path(message_id: message.id))
      expect(message.reload.read_for?(user)).to eq(false)

      post star_message_path(message)
      expect(response).to redirect_to(root_path(message_id: message.id))
      expect(message.reload.starred_for?(user)).to eq(true)

      post unstar_message_path(message)
      expect(response).to redirect_to(root_path(message_id: message.id))
      expect(message.reload.starred_for?(user)).to eq(false)

      post junk_message_path(message)
      expect(response).to redirect_to(root_path(mailbox: :junk))
      expect(message.reload.effective_system_state_for(user)).to eq("junk")

      post not_junk_message_path(message)
      expect(response).to redirect_to(root_path(message_id: message.id))
      expect(message.reload.effective_system_state_for(user)).to eq("inbox")
    end

    it "updates sender policies from the message view" do
      user = create(:user)
      login_user(user)
      inbox = create(:inbox, local_part: "leo")
      message = create(:message, inbox: inbox, from_address: "person@example.com")

      post block_sender_message_path(message)
      expect(response).to redirect_to(root_path(message_id: message.id))
      expect(message.reload.sender_blocked_for?(user)).to eq(true)

      post trust_sender_message_path(message)
      expect(response).to redirect_to(root_path(message_id: message.id))
      expect(message.reload.sender_trusted_for?(user)).to eq(true)

      post block_domain_message_path(message)
      expect(response).to redirect_to(root_path(message_id: message.id))
      expect(message.reload.domain_blocked_for?(user)).to eq(true)

      post unblock_domain_message_path(message)
      expect(response).to redirect_to(root_path(message_id: message.id))
      expect(message.reload.domain_blocked_for?(user)).to eq(false)
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

      expect(response.body).to include("[SENT]")
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

    it "does not leak other users' drafts into the current user's inbox" do
      user = create(:user)
      other_user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      create(:outbound_message, user: user, domain: inbox.domain, source_message: nil, subject: "My saved draft", metadata: {"draft_kind" => "compose"})
      create(:outbound_message, user: other_user, domain: inbox.domain, source_message: nil, subject: "Someone else's draft", metadata: {"draft_kind" => "compose"})

      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Someone else&#39;s draft")
      expect(user.outbound_messages.drafts.pluck(:subject)).to include("My saved draft")
    end

    it "does not open another user's draft from the inbox UI" do
      user = create(:user)
      other_user = create(:user)
      login_user(user)
      inbox = create(:inbox, domain: create(:domain, :with_outbound_configuration, name: "domain.test"), local_part: "leo")
      outbound_message = create(:outbound_message, user: other_user, domain: inbox.domain, source_message: nil, subject: "Private draft", metadata: {"draft_kind" => "compose"})

      get root_path, params: {inbox_id: inbox.id, outbound_message_id: outbound_message.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to include("[INBOX]")
      expect(response.body).not_to include("Private draft")
      expect(response.body).not_to include("Sending from domain.test")
    end
  end
end
