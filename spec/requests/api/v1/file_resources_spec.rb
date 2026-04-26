require "rails_helper"

RSpec.describe "API::V1::FileResources", type: :request do
  let(:user) { create(:user) }
  let(:headers) { api_headers_for(user) }

  describe "albums" do
    it "creates, lists, updates, shows, and deletes albums within the current user scope" do
      create(:drive_album, name: "Other user album")

      post "/api/v1/albums", params: {
        drive_album: {
          name: "Highlights"
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      payload = JSON.parse(response.body).fetch("data")
      album_id = payload.fetch("id")
      expect(payload).to include(
        "name" => "Highlights",
        "user_id" => user.id,
        "stored_file_ids" => [],
        "media_file_count" => 0
      )

      get "/api/v1/albums", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("id") }).to eq([album_id])

      get "/api/v1/albums/#{album_id}", headers: headers
      expect(response).to have_http_status(:ok)

      patch "/api/v1/albums/#{album_id}", params: {
        drive_album: {
          name: "Receipts"
        }
      }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "name")).to eq("Receipts")

      delete "/api/v1/albums/#{album_id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(DriveAlbum.exists?(album_id)).to eq(false)
    end

    it "scopes album access to the current user" do
      album = create(:drive_album)

      get "/api/v1/albums/#{album.id}", headers: headers
      expect(response).to have_http_status(:not_found)

      patch "/api/v1/albums/#{album.id}", params: {
        drive_album: {name: "Private"}
      }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

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

    it "filters root folders and searches by name" do
      root_match = create(:folder, user: user, parent: nil, name: "Invoices")
      root_other = create(:folder, user: user, parent: nil, name: "Photos")
      create(:folder, user: user, parent: root_match, name: "Nested Invoices")

      get "/api/v1/folders", params: {parent_id: "root"}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("id") }).to contain_exactly(root_match.id, root_other.id)

      get "/api/v1/folders", params: {parent_id: "root", q: "inv"}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("id") }).to eq([root_match.id])
    end
  end

  describe "files" do
    it "creates, lists, shows, updates, and deletes metadata-first file records" do
      folder = create(:folder, user: user, name: "Uploads")
      album = create(:drive_album, user: user, name: "Highlights")
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
          drive_album_ids: [album.id],
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
        "drive_album_ids" => [album.id],
        "local_blob" => false,
        "downloadable" => false,
        "image_metadata" => {"width" => 1600, "height" => 900}
      )
      expect(payload["download_url"]).to be_nil
      expect(payload["upload_url"]).to eq("/api/v1/files/#{file_id}/upload")

      get "/api/v1/files", params: {folder_id: folder.id}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("id") }).to eq([file_id])

      get "/api/v1/files/#{file_id}", headers: headers
      expect(response).to have_http_status(:ok)

      patch "/api/v1/files/#{file_id}", params: {
        stored_file: {
          filename: "photo-renamed.png",
          drive_album_ids: [],
          metadata: {"checksum" => "xyz987"}
        }
      }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "filename")).to eq("photo-renamed.png")
      expect(JSON.parse(response.body).dig("data", "drive_album_ids")).to eq([])

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
        },
        blob_signed_id: blob.signed_id
      }, headers: headers

      expect(response).to have_http_status(:created)
      payload = JSON.parse(response.body).fetch("data")
      expect(payload).to include(
        "active_storage_blob_id" => blob.id,
        "filename" => "avatar.png",
        "mime_type" => "image/png",
        "byte_size" => blob.byte_size,
        "local_blob" => true,
        "downloadable" => true,
        "download_url" => "/api/v1/files/#{payload.fetch("id")}/download",
        "image_metadata" => {"width" => 400, "height" => 300}
      )
    end

    it "creates direct upload metadata for client-side uploads" do
      post "/api/v1/direct_uploads", params: {
        blob: {
          filename: "upload.txt",
          byte_size: 13,
          checksum: "YWJjMTIzNDU2Nzg5MDEyMzQ1Ng==",
          content_type: "text/plain",
          metadata: {"origin" => "api"}
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      payload = JSON.parse(response.body).fetch("data")
      expect(payload.fetch("signed_id")).to be_present
      expect(payload).to include(
        "filename" => "upload.txt",
        "byte_size" => 13,
        "content_type" => "text/plain"
      )
      expect(payload.dig("direct_upload", "url")).to be_present
      expect(payload.dig("direct_upload", "headers")).to be_a(Hash)
    end

    it "creates a file record from a direct-uploaded blob and downloads it" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("uploaded file\n"),
        filename: "upload.txt",
        content_type: "text/plain"
      )

      post "/api/v1/files", params: {
        stored_file: {
          source: "local"
        },
        blob_signed_id: blob.signed_id
      }, headers: headers

      expect(response).to have_http_status(:created)
      payload = JSON.parse(response.body).fetch("data")
      file_id = payload.fetch("id")
      expect(payload).to include(
        "filename" => "upload.txt",
        "mime_type" => "text/plain",
        "local_blob" => true,
        "downloadable" => true
      )

      get "/api/v1/files/#{file_id}/download", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("uploaded file")
      expect(response.headers["Content-Disposition"]).to include("attachment")
    end

    it "links direct-uploaded content to an existing metadata-only file" do
      stored_file = create(:stored_file, user: user, folder: nil, active_storage_blob_id: nil, filename: "remote.txt", mime_type: "text/plain", byte_size: 10)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("uploaded file\n"),
        filename: "upload.txt",
        content_type: "text/plain"
      )

      post "/api/v1/files/#{stored_file.id}/upload", params: {
        blob_signed_id: blob.signed_id
      }, headers: headers

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body).fetch("data")
      expect(payload).to include(
        "filename" => "upload.txt",
        "downloadable" => true,
        "local_blob" => true
      )

      get "/api/v1/files/#{stored_file.id}/download", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("uploaded file")
    end

    it "returns not found for metadata-only downloads" do
      stored_file = create(:stored_file, user: user, active_storage_blob_id: nil, filename: "remote.txt", mime_type: "text/plain", byte_size: 12)

      get "/api/v1/files/#{stored_file.id}/download", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body).fetch("error")).to eq("File content is not available")
    end

    it "rejects upload requests without a file" do
      stored_file = create(:stored_file, user: user)

      post "/api/v1/files/#{stored_file.id}/upload", headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body).fetch("error")).to eq("No blob reference provided")
    end

    it "rejects invalid blob references" do
      stored_file = create(:stored_file, user: user)

      post "/api/v1/files/#{stored_file.id}/upload", params: {
        blob_signed_id: "bad-reference"
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).fetch("error")).to eq("Invalid blob reference")
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

    it "filters root files and searches by filename" do
      folder = create(:folder, user: user, name: "Nested")
      root_match = create(:stored_file, root_level: true, user: user, filename: "invoice.pdf")
      root_other = create(:stored_file, root_level: true, user: user, filename: "photo.jpg")
      create(:stored_file, user: user, folder: folder, filename: "nested-invoice.pdf")

      get "/api/v1/files", params: {folder_id: "root"}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("id") }).to contain_exactly(root_match.id, root_other.id)

      get "/api/v1/files", params: {folder_id: "root", q: "inv"}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("id") }).to eq([root_match.id])
    end

    it "scopes upload and download access to the current user" do
      stored_file = create(:stored_file)

      get "/api/v1/files/#{stored_file.id}/download", headers: headers
      expect(response).to have_http_status(:not_found)

      post "/api/v1/files/#{stored_file.id}/upload", params: {
        blob_signed_id: ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("uploaded file\n"),
          filename: "upload.txt",
          content_type: "text/plain"
        ).signed_id
      }, headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "assigns a media file to multiple albums on update" do
      first_album = create(:drive_album, user: user, name: "Highlights")
      second_album = create(:drive_album, user: user, name: "Deliverables")
      stored_file = create(:stored_file, root_level: true, user: user, filename: "cover.png", mime_type: "image/png")

      patch "/api/v1/files/#{stored_file.id}", params: {
        stored_file: {
          drive_album_ids: [first_album.id, second_album.id]
        }
      }, headers: headers

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body).fetch("data")
      expect(payload.fetch("drive_album_ids")).to match_array([first_album.id, second_album.id])
      expect(payload.fetch("drive_albums").map { |album| album.fetch("name") }).to eq(["Deliverables", "Highlights"])
    end

    it "rejects album assignment for non-media files" do
      album = create(:drive_album, user: user, name: "Highlights")
      stored_file = create(:stored_file, root_level: true, user: user, filename: "notes.txt", mime_type: "text/plain")

      patch "/api/v1/files/#{stored_file.id}", params: {
        stored_file: {
          drive_album_ids: [album.id]
        }
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).dig("details", "drive_album_ids").join(" ")).to include("must be an image or video")
    end
  end

  describe "notes" do
    it "creates, lists, shows, updates, and deletes notes within the notes workspace" do
      notes_root = create(:folder, user: user, name: "Notes", parent: nil, metadata: {"app" => "notes", "role" => "root"})
      folder = create(:folder, user: user, parent: notes_root, name: "Specs")
      create(:stored_file, filename: "other.txt")

      post "/api/v1/notes", params: {
        note: {
          folder_id: folder.id,
          title: "Roadmap",
          body: "# Roadmap\n\n- ship notes"
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      payload = JSON.parse(response.body).fetch("data")
      note_id = payload.fetch("id")
      expect(payload).to include(
        "folder_id" => folder.id,
        "title" => "Roadmap",
        "filename" => "Roadmap.md",
        "mime_type" => "text/markdown",
        "body" => "# Roadmap\n\n- ship notes"
      )
      expect(payload.dig("folder", "id")).to eq(folder.id)
      expect(payload.dig("folder", "name")).to eq("Specs")

      get "/api/v1/notes", params: {folder_id: folder.id}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data").map { |entry| entry.fetch("id") }).to eq([note_id])

      get "/api/v1/notes/#{note_id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "body")).to eq("# Roadmap\n\n- ship notes")

      patch "/api/v1/notes/#{note_id}", params: {
        note: {
          title: "Roadmap v2",
          body: "## Updated"
        }
      }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "title")).to eq("Roadmap v2")

      note = user.stored_files.find(note_id)
      expect(note.filename).to eq("Roadmap v2.md")
      expect(note.blob.download).to eq("## Updated")

      delete "/api/v1/notes/#{note_id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(StoredFile.exists?(note_id)).to eq(false)
    end

    it "creates the notes root folder and defaults new notes into it" do
      expect {
        post "/api/v1/notes", params: {
          note: {
            title: "Inbox",
            body: "Hello"
          }
        }, headers: headers
      }.to change { user.folders.where(parent_id: nil, name: "Notes").count }.from(0).to(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body).dig("data", "filename")).to eq("Inbox.md")
      expect(user.stored_files.last.folder.name).to eq("Notes")
    end

    it "rejects folders outside the notes workspace" do
      other_folder = create(:folder, user: user, name: "Drive")

      post "/api/v1/notes", params: {
        note: {
          folder_id: other_folder.id,
          title: "Secret",
          body: "Nope"
        }
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).dig("details", "folder_id")).to include("Folder must be within the Notes workspace")
    end

    it "rejects notes folders owned by another user" do
      foreign_user = create(:user)
      foreign_root = create(:folder, user: foreign_user, name: "Notes", parent: nil, metadata: {"app" => "notes", "role" => "root"})
      foreign_folder = create(:folder, user: foreign_user, parent: foreign_root, name: "Private")

      post "/api/v1/notes", params: {
        note: {
          folder_id: foreign_folder.id,
          title: "Secret",
          body: "Nope"
        }
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body).dig("details", "folder_id")).to include("Folder must be within the Notes workspace")
    end

    it "scopes note access to the current user" do
      other_user = create(:user)
      other_root = create(:folder, user: other_user, name: "Notes", parent: nil, metadata: {"app" => "notes", "role" => "root"})
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("hidden"),
        filename: "Hidden.md",
        content_type: "text/markdown"
      )
      note = create(:stored_file,
        user: other_user,
        folder: other_root,
        filename: "Hidden.md",
        mime_type: "text/markdown",
        byte_size: blob.byte_size,
        active_storage_blob_id: blob.id,
        image_width: nil,
        image_height: nil)

      get "/api/v1/notes/#{note.id}", headers: headers
      expect(response).to have_http_status(:not_found)

      patch "/api/v1/notes/#{note.id}", params: {
        note: {title: "Visible", body: "changed"}
      }, headers: headers
      expect(response).to have_http_status(:not_found)

      delete "/api/v1/notes/#{note.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns the notes folder tree with child folders and note counts" do
      notes_root = create(:folder, user: user, name: "Notes", parent: nil, metadata: {"app" => "notes", "role" => "root"})
      projects = create(:folder, user: user, parent: notes_root, name: "Projects")
      specs = create(:folder, user: user, parent: projects, name: "Specs")

      first_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("# Root"),
        filename: "Root.md",
        content_type: "text/markdown"
      )
      second_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("# Specs"),
        filename: "Specs.md",
        content_type: "text/markdown"
      )

      create(:stored_file,
        user: user,
        folder: notes_root,
        filename: "Root.md",
        mime_type: "text/markdown",
        byte_size: first_blob.byte_size,
        active_storage_blob_id: first_blob.id,
        image_width: nil,
        image_height: nil)
      create(:stored_file,
        user: user,
        folder: specs,
        filename: "Specs.md",
        mime_type: "text/markdown",
        byte_size: second_blob.byte_size,
        active_storage_blob_id: second_blob.id,
        image_width: nil,
        image_height: nil)

      get "/api/v1/notes/tree", headers: headers

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body).fetch("data")
      expect(payload).to include(
        "id" => notes_root.id,
        "name" => "Notes",
        "note_count" => 1,
        "child_folder_count" => 1
      )
      expect(payload.dig("children", 0, "id")).to eq(projects.id)
      expect(payload.dig("children", 0, "name")).to eq("Projects")
      expect(payload.dig("children", 0, "children", 0, "id")).to eq(specs.id)
      expect(payload.dig("children", 0, "children", 0, "note_count")).to eq(1)
    end
  end
end
