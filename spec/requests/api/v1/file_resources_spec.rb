require "rails_helper"

RSpec.describe "API::V1::FileResources", type: :request do
  let(:user) { create(:user) }
  let(:headers) { api_headers_for(user) }

  describe "folders" do
    it "creates, lists, updates, shows, and deletes folders within the current user scope" do
      parent = create(:folder, user: user, name: "Projects")
      create(:folder, name: "Other user folder")

      post "/api/v1/folders", params: {
        folder: {
          parent_id: parent.id,
          name: "Photos",
          source: "provider",
          provider: "google_drive",
          provider_identifier: "folder-123",
          metadata: {"color" => "blue"}
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      payload = JSON.parse(response.body).fetch("data")
      folder_id = payload.fetch("id")
      expect(payload).to include(
        "parent_id" => parent.id,
        "name" => "Photos",
        "source" => "provider",
        "provider" => "google_drive",
        "provider_identifier" => "folder-123"
      )

      get "/api/v1/folders", params: {parent_id: parent.id}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("id") }).to eq([folder_id])

      get "/api/v1/folders/#{folder_id}", headers: headers
      expect(response).to have_http_status(:ok)

      patch "/api/v1/folders/#{folder_id}", params: {
        folder: {
          name: "Receipts",
          metadata: {"color" => "green"}
        }
      }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "name")).to eq("Receipts")

      delete "/api/v1/folders/#{folder_id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Folder.exists?(folder_id)).to eq(false)
    end

    it "rejects parent folders owned by another user" do
      foreign_parent = create(:folder)

      post "/api/v1/folders", params: {
        folder: {
          parent_id: foreign_parent.id,
          name: "Private"
        }
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).dig("details", "parent_id")).to include("Parent must belong to the same user")
    end
  end

  describe "files" do
    it "creates, lists, shows, updates, and deletes metadata-first file records" do
      folder = create(:folder, user: user, name: "Uploads")
      create(:stored_file, filename: "other.txt")

      post "/api/v1/files", params: {
        stored_file: {
          folder_id: folder.id,
          filename: "photo.png",
          mime_type: "image/png",
          byte_size: 2048,
          source: "provider",
          provider: "google_drive",
          provider_identifier: "file-123",
          provider_created_at: "2026-04-10T10:00:00Z",
          provider_updated_at: "2026-04-11T10:00:00Z",
          image_width: 1600,
          image_height: 900,
          metadata: {"checksum" => "abc123"}
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      payload = JSON.parse(response.body).fetch("data")
      file_id = payload.fetch("id")
      expect(payload).to include(
        "folder_id" => folder.id,
        "filename" => "photo.png",
        "mime_type" => "image/png",
        "byte_size" => 2048,
        "source" => "provider",
        "provider" => "google_drive",
        "provider_identifier" => "file-123",
        "local_blob" => false,
        "image_metadata" => {"width" => 1600, "height" => 900}
      )

      get "/api/v1/files", params: {folder_id: folder.id}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("id") }).to eq([file_id])

      get "/api/v1/files/#{file_id}", headers: headers
      expect(response).to have_http_status(:ok)

      patch "/api/v1/files/#{file_id}", params: {
        stored_file: {
          filename: "photo-renamed.png",
          metadata: {"checksum" => "xyz987"}
        }
      }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "filename")).to eq("photo-renamed.png")

      delete "/api/v1/files/#{file_id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(StoredFile.exists?(file_id)).to eq(false)
    end

    it "syncs metadata from an attached blob when a blob link is provided" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("blob content"),
        filename: "avatar.png",
        content_type: "image/png",
        metadata: {"width" => 400, "height" => 300}
      )

      post "/api/v1/files", params: {
        stored_file: {
          filename: "",
          active_storage_blob_id: blob.id,
          source: "local"
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      payload = JSON.parse(response.body).fetch("data")
      expect(payload).to include(
        "active_storage_blob_id" => blob.id,
        "filename" => "avatar.png",
        "mime_type" => "image/png",
        "byte_size" => blob.byte_size,
        "local_blob" => true,
        "image_metadata" => {"width" => 400, "height" => 300}
      )
    end

    it "rejects folders owned by another user" do
      foreign_folder = create(:folder)

      post "/api/v1/files", params: {
        stored_file: {
          folder_id: foreign_folder.id,
          filename: "secret.txt"
        }
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).dig("details", "folder_id")).to include("Folder must belong to the same user")
    end
  end
end
