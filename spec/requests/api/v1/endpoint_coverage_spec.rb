require "rails_helper"

RSpec.describe "API::V1::EndpointCoverage", type: :request do
  let(:user) { create(:user) }
  let(:headers) { api_headers_for(user) }

  it "covers api key show, update, and destroy" do
    api_key = create(:api_key, user: user, name: "Original")

    get "/api/v1/api_keys/#{api_key.id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", "name")).to eq("Original")

    patch "/api/v1/api_keys/#{api_key.id}", params: {
      api_key: {name: "Renamed"}
    }, headers: headers
    expect(response).to have_http_status(:ok)
    expect(api_key.reload.name).to eq("Renamed")

    delete "/api/v1/api_keys/#{api_key.id}", headers: headers
    expect(response).to have_http_status(:no_content)
    expect(APIKey.exists?(api_key.id)).to eq(false)
  end

  it "covers domain index, show, update, and destroy" do
    domain = create(:domain, name: "alpha.test")

    get "/api/v1/domains", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("name") }).to include("alpha.test")

    get "/api/v1/domains/#{domain.id}", headers: headers
    expect(response).to have_http_status(:ok)

    patch "/api/v1/domains/#{domain.id}", params: {
      domain: {active: false}
    }, headers: headers
    expect(response).to have_http_status(:ok)
    expect(domain.reload.active).to eq(false)

    deletable = create(:domain, name: "delete-me.test")
    delete "/api/v1/domains/#{deletable.id}", headers: headers
    expect(response).to have_http_status(:no_content)
  end

  it "covers folder and file metadata endpoints" do
    folder = create(:folder, user: user)
    stored_file = create(:stored_file, user: user, folder: folder)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("uploaded file\n"),
      filename: "upload.txt",
      content_type: "text/plain"
    )

    post "/api/v1/direct_uploads", params: {
      blob: {
        filename: "upload.txt",
        byte_size: 13,
        checksum: "YWJjMTIzNDU2Nzg5MDEyMzQ1Ng==",
        content_type: "text/plain"
      }
    }, headers: headers
    expect(response).to have_http_status(:created)

    get "/api/v1/folders", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/folders/#{folder.id}", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/files", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/files/#{stored_file.id}", headers: headers
    expect(response).to have_http_status(:ok)

    post "/api/v1/files/#{stored_file.id}/upload", params: {
      blob_signed_id: blob.signed_id
    }, headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/files/#{stored_file.id}/download", headers: headers
    expect(response).to have_http_status(:ok)
  end

  it "covers note index, tree, and show" do
    notes_root = create(:folder, user: user, name: "Notes", parent: nil, metadata: {"app" => "notes", "role" => "root"})
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("# Draft"),
      filename: "Draft.md",
      content_type: "text/markdown"
    )
    note = create(:stored_file,
      user: user,
      folder: notes_root,
      filename: "Draft.md",
      mime_type: "text/markdown",
      byte_size: blob.byte_size,
      active_storage_blob_id: blob.id,
      image_width: nil,
      image_height: nil)

    get "/api/v1/notes", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/notes/tree", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/notes/#{note.id}", headers: headers
    expect(response).to have_http_status(:ok)
  end

  it "covers inbox index, show, update, destroy, and nested inbox routes" do
    inbox = create(:inbox, local_part: "support")
    conversation = create(:conversation)
    create(:message, inbox: inbox, conversation: conversation, subject: "Inbox message")

    get "/api/v1/inboxes", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/inboxes/#{inbox.id}", headers: headers
    expect(response).to have_http_status(:ok)

    patch "/api/v1/inboxes/#{inbox.id}", params: {
      inbox: {description: "Updated description"}
    }, headers: headers
    expect(response).to have_http_status(:ok)
    expect(inbox.reload.description).to eq("Updated description")

    get "/api/v1/inboxes/#{inbox.id}/messages", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("data").size).to eq(1)

    get "/api/v1/inboxes/#{inbox.id}/conversations", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("data").size).to eq(1)

    deletable = create(:inbox, local_part: "trash", domain: create(:domain, name: "trash.test"))
    delete "/api/v1/inboxes/#{deletable.id}", headers: headers
    expect(response).to have_http_status(:no_content)
  end

  it "covers message show, triage actions, inline assets, conversation index/show, and conversation messages" do
    inbox = create(:inbox)
    conversation = create(:conversation)
    message = create(:message, inbox: inbox, conversation: conversation, subject: "Threaded")

    get "/api/v1/messages/#{message.id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", "subject")).to eq("Threaded")

    post "/api/v1/messages/#{message.id}/mark_read", headers: headers
    expect(response).to have_http_status(:ok)

    post "/api/v1/messages/#{message.id}/star", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/messages/#{message.id}/inline_assets/bad-token", headers: headers
    expect(response).to have_http_status(:not_found)

    get "/api/v1/conversations", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/conversations/#{conversation.id}", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/conversations/#{conversation.id}/messages", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("data").size).to eq(1)
  end

  it "covers outbound index, show, queue, attachments index, and destroy" do
    outbound_message = create(:outbound_message, user: user)
    outbound_message.attachments.attach(
      io: StringIO.new("attachment body"),
      filename: "note.txt",
      content_type: "text/plain"
    )

    get "/api/v1/outbound_messages", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/outbound_messages/#{outbound_message.id}", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/outbound_messages/#{outbound_message.id}/attachments", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("data").size).to eq(1)

    post "/api/v1/outbound_messages/#{outbound_message.id}/queue", headers: headers
    expect(response).to have_http_status(:ok)
    expect(outbound_message.reload).to be_queued

    deletable = create(:outbound_message, user: user)
    delete "/api/v1/outbound_messages/#{deletable.id}", headers: headers
    expect(response).to have_http_status(:no_content)
  end

  it "covers notification show and pipeline show" do
    WelcomeNotifier.with({}).deliver(user)
    notification = user.notifications.last

    get "/api/v1/notifications/#{notification.id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", "id")).to eq(notification.id)

    get "/api/v1/pipelines/default", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", "key")).to eq("default")
  end
end
