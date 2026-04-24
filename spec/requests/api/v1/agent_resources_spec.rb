require "rails_helper"

RSpec.describe "API::V1::AgentResources", type: :request do
  let(:user) { create(:user) }
  let(:headers) { api_headers_for(user) }

  describe "mailboxes" do
    it "returns mailbox counts and supporting resources" do
      inbox = create(:inbox, domain: create(:domain, user: user))
      create(:message, inbox: inbox)
      create(:label, user: user, name: "VIP")

      get "/api/v1/mailboxes", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body).fetch("data")
      expect(json.fetch("mailboxes").map { |entry| entry.fetch("name") }).to include("inbox", "drafts", "sent")
      expect(json.fetch("labels").map { |entry| entry.fetch("name") }).to include("VIP")
      expect(json.fetch("inboxes")).not_to be_empty
      expect(json.fetch("domains")).not_to be_empty
    end
  end

  describe "sender policies" do
    it "supports CRUD and filtering" do
      post "/api/v1/sender_policies", params: {
        sender_policy: {
          kind: "sender",
          disposition: "blocked",
          value: "blocked@example.com"
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      policy_id = JSON.parse(response.body).dig("data", "id")

      get "/api/v1/sender_policies", params: {kind: "sender", disposition: "blocked"}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", 0, "value")).to eq("blocked@example.com")

      patch "/api/v1/sender_policies/#{policy_id}", params: {
        sender_policy: {disposition: "trusted"}
      }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "disposition")).to eq("trusted")

      delete "/api/v1/sender_policies/#{policy_id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "templates and signatures" do
    it "supports email template CRUD and draft insertion" do
      domain = create(:domain, :with_outbound_configuration, user: user)

      post "/api/v1/email_templates", params: {
        email_template: {
          domain_id: domain.id,
          name: "Follow Up",
          subject: "Checking in",
          body: "<div>Template body</div>"
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      template_id = JSON.parse(response.body).dig("data", "id")

      get "/api/v1/email_templates", params: {domain_id: domain.id}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", 0, "name")).to eq("Follow Up")

      outbound_message = create(:outbound_message, user: user, domain: domain, subject: nil)

      post "/api/v1/outbound_messages/#{outbound_message.id}/insert_template", params: {template_id: template_id}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "subject")).to eq("Checking in")
      expect(outbound_message.reload.body.to_s).to include("Template body")
    end

    it "supports email signature CRUD and compose bootstrap" do
      domain = create(:domain, :with_outbound_configuration, user: user)
      inbox = create(:inbox, domain: domain)

      post "/api/v1/email_signatures", params: {
        email_signature: {
          domain_id: domain.id,
          name: "Default",
          is_default: true,
          body: "<div>-- Team</div>"
        }
      }, headers: headers

      expect(response).to have_http_status(:created)

      post "/api/v1/outbound_messages/compose", params: {inbox_id: inbox.id}, headers: headers

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body).dig("data", "inbox_id")).to eq(inbox.id)
      expect(JSON.parse(response.body).dig("data", "body_html")).to include("-- Team")
      expect(JSON.parse(response.body).dig("data", "status")).to eq("draft")
    end
  end

  describe "me" do
    it "updates avatar metadata" do
      file = fixture_file_upload("avatar.svg", "image/svg+xml")

      patch "/api/v1/me", params: {
        user: {
          name: "Avatar User",
          avatar: file
        }
      }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "avatar", "filename")).to eq("avatar.svg")
    end
  end

  describe "calendars and events" do
    it "supports calendar CRUD, event CRUD, linked messages, and occurrence queries" do
      post "/api/v1/calendars", params: {
        calendar: {
          name: "Work",
          color: "amber",
          time_zone: "UTC",
          position: 1
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      calendar_id = JSON.parse(response.body).dig("data", "id")

      post "/api/v1/calendar_events", params: {
        calendar_event: {
          calendar_id: calendar_id,
          title: "Launch Review",
          description: "Agenda review",
          location: "War Room",
          all_day: false,
          start_date: "2026-04-15",
          end_date: "2026-04-15",
          start_time: "10:00",
          end_time: "11:00",
          time_zone: "UTC",
          status: "confirmed",
          recurrence_frequency: "weekly",
          recurrence_interval: 1,
          recurrence_weekdays: ["WE"]
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      event_id = JSON.parse(response.body).dig("data", "id")

      get "/api/v1/calendar_events", params: {calendar_id: calendar_id}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", 0, "title")).to eq("Launch Review")

      get "/api/v1/calendar_occurrences", params: {
        calendar_id: calendar_id,
        starts_from: "2026-04-15T00:00:00Z",
        ends_to: "2026-04-30T23:59:59Z"
      }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data")).not_to be_empty

      inbox = create(:inbox)
      message = create(:message, inbox: inbox)
      create(:calendar_event_link, calendar_event_id: event_id, message: message, ical_uid: "uid-1", ical_method: "REQUEST")

      get "/api/v1/calendar_events/#{event_id}/messages", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", 0, "id")).to eq(message.id)

      patch "/api/v1/calendar_events/#{event_id}", params: {
        calendar_event: {
          calendar_id: calendar_id,
          title: "Launch Review Updated",
          description: "Agenda review",
          location: "Bridge",
          all_day: false,
          start_date: "2026-04-15",
          end_date: "2026-04-15",
          start_time: "10:30",
          end_time: "11:30",
          time_zone: "UTC",
          status: "tentative"
        }
      }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "status")).to eq("tentative")

      delete "/api/v1/calendar_events/#{event_id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end

    it "imports ICS files into a calendar" do
      calendar = create(:calendar, user: user)
      tempfile = Tempfile.new(["calendar-import", ".ics"])
      tempfile.write(<<~ICS)
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Telex Specs//EN
        BEGIN:VEVENT
        UID:import-1
        SUMMARY:Imported Event
        DTSTART:20260420T100000Z
        DTEND:20260420T110000Z
        END:VEVENT
        END:VCALENDAR
      ICS
      tempfile.rewind
      file = Rack::Test::UploadedFile.new(tempfile.path, "text/calendar")

      post "/api/v1/calendars/#{calendar.id}/import_ics", params: {file: file}, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "created")).to eq(1)
    ensure
      tempfile.close!
    end
  end

  describe "message invitations" do
    it "syncs and updates invitation responses" do
      inbox = create(:inbox, local_part: "support")
      source = build_calendar_invitation_email(to: inbox.address, attendee_email: user.email_address, uid: "invite-42")
      inbound_email = create(:action_mailbox_inbound_email, source: source)
      message = create(:message, inbox: inbox, inbound_email: inbound_email)
      invite = Calendars::InvitationExtractor.call(message: message)
      message.update!(metadata: {"calendar_invitation" => invite.metadata})

      get "/api/v1/messages/#{message.id}/invitation", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "available")).to eq(true)
      expect(JSON.parse(response.body).dig("data", "calendar_event", "uid")).to eq("invite-42")

      post "/api/v1/messages/#{message.id}/invitation/sync", headers: headers
      expect(response).to have_http_status(:ok)

      patch "/api/v1/messages/#{message.id}/invitation", params: {
        invitation: {participation_status: "accepted"}
      }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "current_user_attendee", "participation_status")).to eq("accepted")
    end
  end
end
