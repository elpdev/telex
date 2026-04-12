require "rails_helper"

RSpec.describe "Drives", type: :request do
  it "renders the root drive page and command palette navigation" do
    user = create(:user)
    login_user(user)
    create(:folder, user: user, name: "Projects")
    create(:stored_file, root_level: true, user: user, filename: "root-note.txt", mime_type: "text/plain", byte_size: 128)

    get drive_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("DRIVE")
    expect(response.body).to include("Projects")
    expect(response.body).to include("root-note.txt")
    expect(response.body).to include("go drive")
    expect(response.body).to include("[ MAIL ]")
    expect(response.body).to include("[ CALENDAR ]")
  end

  it "renders a canonical folder page with children and files" do
    user = create(:user)
    login_user(user)
    folder = create(:folder, user: user, name: "Projects")
    create(:folder, user: user, parent: folder, name: "Q2")
    create(:stored_file, user: user, folder: folder, filename: "brief.pdf", mime_type: "application/pdf", byte_size: 2048)

    get drives_folder_path(folder)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Projects")
    expect(response.body).to include("Q2")
    expect(response.body).to include("brief.pdf")
  end

  it "renders the new file page for a folder" do
    user = create(:user)
    login_user(user)
    folder = create(:folder, user: user, name: "Uploads")

    get new_drives_file_path, params: {folder_id: folder.id}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("NEW FILE")
    expect(response.body).to include(%(action="#{drives_files_path}"))
  end

  it "creates a folder and redirects to the parent location" do
    user = create(:user)
    login_user(user)
    parent = create(:folder, user: user, name: "Projects")

    post drives_folders_path, params: {
      folder: {
        parent_id: parent.id,
        name: "Assets",
        source: "local"
      }
    }

    expect(response).to redirect_to(drives_folder_path(parent))
    expect(parent.children.find_by(name: "Assets")).to be_present
  end

  it "creates a stored file from a direct upload signed id" do
    user = create(:user)
    login_user(user)
    folder = create(:folder, user: user, name: "Uploads")
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("drive upload body"),
      filename: "upload.txt",
      content_type: "text/plain"
    )

    post drives_files_path, params: {
      stored_file: {
        folder_id: folder.id,
        filename: "",
        source: "local"
      },
      blob_signed_id: blob.signed_id
    }

    expect(response).to redirect_to(drives_folder_path(folder))
    stored_file = user.stored_files.order(:id).last
    expect(stored_file.filename).to eq("upload.txt")
    expect(stored_file.active_storage_blob_id).to eq(blob.id)
  end

  it "downloads a blob-backed file" do
    user = create(:user)
    login_user(user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("download me"),
      filename: "download.txt",
      content_type: "text/plain"
    )
    stored_file = create(:stored_file, root_level: true, user: user, filename: "download.txt", mime_type: "text/plain", byte_size: blob.byte_size, active_storage_blob_id: blob.id)

    get download_drives_file_path(stored_file)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("download me")
    expect(response.headers["Content-Disposition"]).to include("attachment")
  end

  it "scopes folder and file access to the current user" do
    user = create(:user)
    login_user(user)
    foreign_folder = create(:folder)
    foreign_file = create(:stored_file)

    get drives_folder_path(foreign_folder)
    expect(response).to have_http_status(:not_found)

    get edit_drives_file_path(foreign_file)
    expect(response).to have_http_status(:not_found)
  end
end
