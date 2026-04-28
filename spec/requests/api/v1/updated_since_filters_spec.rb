require "rails_helper"

RSpec.describe "API::V1 updated_since filters", type: :request do
  let(:user) { create(:user) }
  let(:headers) { api_headers_for(user) }
  let(:cursor) { Time.zone.parse("2026-04-20 12:00:00") }
  let(:before_cursor) { cursor - 1.hour }
  let(:after_cursor) { cursor + 1.hour }

  it "filters messages by message updates and user message organization updates" do
    inbox = create(:inbox, domain: create(:domain, user: user), local_part: "support")
    old_message = create(:message, inbox: inbox, subject: "Old")
    changed_message = create(:message, inbox: inbox, subject: "Changed")
    organization_changed_message = create(:message, inbox: inbox, subject: "Read later")

    old_message.update_columns(updated_at: before_cursor)
    changed_message.update_columns(updated_at: after_cursor)
    organization_changed_message.update_columns(updated_at: before_cursor)
    create(:message_organization, user: user, message: organization_changed_message, updated_at: after_cursor)

    get "/api/v1/messages", params: {updated_since: cursor.iso8601, sort: "subject"}, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response_ids).to contain_exactly(changed_message.id, organization_changed_message.id)
  end

  it "filters Drive folders and files by updates" do
    old_folder = create(:folder, user: user, name: "Old Folder")
    changed_folder = create(:folder, user: user, name: "Changed Folder")
    old_file = create(:stored_file, user: user, folder: changed_folder, filename: "old.png")
    changed_file = create(:stored_file, user: user, folder: changed_folder, filename: "changed.png")

    old_folder.update_columns(updated_at: before_cursor)
    changed_folder.update_columns(updated_at: after_cursor)
    old_file.update_columns(updated_at: before_cursor)
    changed_file.update_columns(updated_at: after_cursor)

    get "/api/v1/folders", params: {updated_since: cursor.iso8601}, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response_ids).to eq([changed_folder.id])

    get "/api/v1/files", params: {folder_id: changed_folder.id, updated_since: cursor.iso8601}, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response_ids).to eq([changed_file.id])
  end

  it "filters Notes by updated markdown files" do
    notes_root = create(:folder, user: user, name: "Notes", metadata: {"app" => "notes", "role" => "root"})
    old_note = create(:stored_file, user: user, folder: notes_root, filename: "old.md", mime_type: "text/markdown")
    changed_note = create(:stored_file, user: user, folder: notes_root, filename: "changed.md", mime_type: "text/markdown")

    old_note.update_columns(updated_at: before_cursor)
    changed_note.update_columns(updated_at: after_cursor)

    get "/api/v1/notes", params: {folder_id: notes_root.id, updated_since: cursor.iso8601}, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response_ids).to eq([changed_note.id])
  end

  it "filters calendars and calendar events by updates" do
    old_calendar = create(:calendar, user: user, name: "Old Calendar")
    changed_calendar = create(:calendar, user: user, name: "Changed Calendar")
    old_event = create(:calendar_event, calendar: changed_calendar, title: "Old Event")
    changed_event = create(:calendar_event, calendar: changed_calendar, title: "Changed Event")

    old_calendar.update_columns(updated_at: before_cursor)
    changed_calendar.update_columns(updated_at: after_cursor)
    user.calendars.where.not(id: [old_calendar.id, changed_calendar.id]).update_all(updated_at: before_cursor)
    old_event.update_columns(updated_at: before_cursor)
    changed_event.update_columns(updated_at: after_cursor)

    get "/api/v1/calendars", params: {updated_since: cursor.iso8601}, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response_ids).to eq([changed_calendar.id])

    get "/api/v1/calendar_events", params: {calendar_id: changed_calendar.id, updated_since: cursor.iso8601}, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response_ids).to eq([changed_event.id])
  end

  it "filters contacts by contact, email address, and note updates" do
    old_contact = create(:contact, user: user, name: "Old Contact")
    changed_contact = create(:contact, user: user, name: "Changed Contact")
    email_changed_contact = create(:contact, user: user, name: "Email Contact")
    note_changed_contact = create(:contact, user: user, name: "Note Contact")
    note_file = create(:stored_file, user: user, filename: "note.md", mime_type: "text/markdown")

    old_contact.update_columns(updated_at: before_cursor)
    changed_contact.update_columns(updated_at: after_cursor)
    email_changed_contact.update_columns(updated_at: before_cursor)
    note_changed_contact.update_columns(updated_at: before_cursor, note_file_id: note_file.id)
    note_file.update_columns(updated_at: after_cursor)
    create(:contact_email_address, contact: email_changed_contact, user: user, updated_at: after_cursor)

    get "/api/v1/contacts", params: {updated_since: cursor.iso8601}, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response_ids).to contain_exactly(changed_contact.id, email_changed_contact.id, note_changed_contact.id)
  end

  it "filters outbound messages and task resources by updates" do
    old_outbound = create(:outbound_message, user: user, subject: "Old Outbound")
    changed_outbound = create(:outbound_message, user: user, subject: "Changed Outbound")
    tasks_root = create(:folder, user: user, name: "Tasks", metadata: {"app" => "tasks", "role" => "root"})
    projects_folder = create(:folder, user: user, parent: tasks_root, name: "Projects", metadata: {"app" => "tasks", "role" => "projects"})
    old_project = create(:folder, user: user, parent: projects_folder, name: "Old Project", metadata: {"app" => "tasks", "role" => "project"})
    changed_project = create(:folder, user: user, parent: projects_folder, name: "Changed Project", metadata: {"app" => "tasks", "role" => "project"})
    cards_folder = create(:folder, user: user, parent: changed_project, name: "cards", metadata: {"app" => "tasks", "role" => "cards"})
    old_card = create(:stored_file, user: user, folder: cards_folder, filename: "old.md", mime_type: "text/markdown")
    changed_card = create(:stored_file, user: user, folder: cards_folder, filename: "changed.md", mime_type: "text/markdown")

    old_outbound.update_columns(updated_at: before_cursor)
    changed_outbound.update_columns(updated_at: after_cursor)
    old_project.update_columns(updated_at: before_cursor)
    changed_project.update_columns(updated_at: after_cursor)
    old_card.update_columns(updated_at: before_cursor)
    changed_card.update_columns(updated_at: after_cursor)

    get "/api/v1/outbound_messages", params: {updated_since: cursor.iso8601}, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response_ids).to eq([changed_outbound.id])

    get "/api/v1/tasks/projects", params: {updated_since: cursor.iso8601}, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response_ids).to eq([changed_project.id])

    get "/api/v1/tasks/projects/#{changed_project.id}/cards", params: {updated_since: cursor.iso8601}, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response_ids).to eq([changed_card.id])
  end

  it "returns bad request for invalid updated_since timestamps" do
    get "/api/v1/files", params: {updated_since: "not-a-time"}, headers: headers

    expect(response).to have_http_status(:bad_request)
  end

  def response_ids
    JSON.parse(response.body).fetch("data").map { |record| record.fetch("id") }
  end
end
