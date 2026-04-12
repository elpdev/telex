require "rails_helper"

RSpec.describe "Drives", type: :request do
  it "renders the root drive page and command palette navigation" do
    user = create(:user)
    login_user(user)
    create(:folder, user: user, name: "Projects")
    image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("image-bytes"),
      filename: "photo.png",
      content_type: "image/png"
    )
    create(:stored_file, root_level: true, user: user, filename: "root-note.txt", mime_type: "text/plain", byte_size: 128)
    create(:stored_file, root_level: true, user: user, filename: "photo.png", mime_type: "image/png", byte_size: image_blob.byte_size, active_storage_blob_id: image_blob.id)

    get drive_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("DRIVE")
    expect(response.body).to include("Projects")
    expect(response.body).to include("root-note.txt")
    expect(response.body).to include("photo.png")
    expect(response.body).to include(%(alt="photo.png"))
    expect(response.body).to include("go drive")
    expect(response.body).to include("[ MAIL ]")
    expect(response.body).to include("[ CALENDAR ]")
    expect(response.body).to include("[ PHOTOS ]")
  end

  it "renders a photos view with image and video files only" do
    user = create(:user)
    login_user(user)
    image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("image-bytes"),
      filename: "camera-roll.png",
      content_type: "image/png"
    )
    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("video-bytes"),
      filename: "clip.mp4",
      content_type: "video/mp4"
    )
    create(:stored_file, root_level: true, user: user, filename: "camera-roll.png", mime_type: "image/png", byte_size: image_blob.byte_size, active_storage_blob_id: image_blob.id)
    create(:stored_file, root_level: true, user: user, filename: "clip.mp4", mime_type: "video/mp4", byte_size: video_blob.byte_size, active_storage_blob_id: video_blob.id)
    create(:stored_file, root_level: true, user: user, filename: "notes.txt", mime_type: "text/plain", byte_size: 120)

    get drives_photos_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("PHOTOS")
    expect(response.body).to include("camera-roll.png")
    expect(response.body).to include("clip.mp4")
    expect(response.body).not_to include("notes.txt")
  end

  it "filters the gallery to only videos" do
    user = create(:user)
    login_user(user)
    image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("image-bytes"),
      filename: "camera-roll.png",
      content_type: "image/png"
    )
    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("video-bytes"),
      filename: "clip.mp4",
      content_type: "video/mp4"
    )
    create(:stored_file, root_level: true, user: user, filename: "camera-roll.png", mime_type: "image/png", byte_size: image_blob.byte_size, active_storage_blob_id: image_blob.id)
    create(:stored_file, root_level: true, user: user, filename: "clip.mp4", mime_type: "video/mp4", byte_size: video_blob.byte_size, active_storage_blob_id: video_blob.id)

    get drives_photos_path, params: {kind: "video"}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("clip.mp4")
    expect(response.body).not_to include("camera-roll.png")
  end

  it "orders gallery items by provider_created_at before created_at" do
    user = create(:user)
    login_user(user)
    older_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("older-image"),
      filename: "older.png",
      content_type: "image/png"
    )
    newer_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("newer-image"),
      filename: "newer.png",
      content_type: "image/png"
    )

    create(:stored_file,
      root_level: true,
      user: user,
      filename: "older.png",
      mime_type: "image/png",
      byte_size: older_blob.byte_size,
      active_storage_blob_id: older_blob.id,
      provider_created_at: Time.zone.parse("2026-04-10 10:00:00"))
    create(:stored_file,
      root_level: true,
      user: user,
      filename: "newer.png",
      mime_type: "image/png",
      byte_size: newer_blob.byte_size,
      active_storage_blob_id: newer_blob.id,
      provider_created_at: Time.zone.parse("2026-04-11 10:00:00"))

    get drives_photos_path

    expect(response).to have_http_status(:ok)
    expect(response.body.index("newer.png")).to be < response.body.index("older.png")
  end

  it "renders gallery preview navigation" do
    user = create(:user)
    login_user(user)
    first_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("first-image"),
      filename: "first.png",
      content_type: "image/png"
    )
    second_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("second-image"),
      filename: "second.png",
      content_type: "image/png"
    )

    first_file = create(:stored_file,
      root_level: true,
      user: user,
      filename: "first.png",
      mime_type: "image/png",
      byte_size: first_blob.byte_size,
      active_storage_blob_id: first_blob.id,
      provider_created_at: Time.zone.parse("2026-04-10 10:00:00"))
    second_file = create(:stored_file,
      root_level: true,
      user: user,
      filename: "second.png",
      mime_type: "image/png",
      byte_size: second_blob.byte_size,
      active_storage_blob_id: second_blob.id,
      provider_created_at: Time.zone.parse("2026-04-11 10:00:00"))

    get drives_photo_path(first_file)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("[ PREVIEW ]")
    expect(response.body).to include(second_file.filename)
    expect(response.body).to include(drives_photo_path(second_file, kind: "all"))
  end

  it "renders a canonical folder page with children and files" do
    user = create(:user)
    login_user(user)
    folder = create(:folder, user: user, name: "Projects")
    child_folder = create(:folder, user: user, parent: folder, name: "Q2")
    create(:folder, user: user, parent: child_folder, name: "Final")
    create(:stored_file, user: user, folder: folder, filename: "brief.pdf", mime_type: "application/pdf", byte_size: 2048)

    get drives_folder_path(folder)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Projects")
    expect(response.body).to include("Q2")
    expect(response.body).to include("Final")
    expect(response.body).to include("brief.pdf")
  end

  it "renders a file detail preview page for images" do
    user = create(:user)
    login_user(user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("image-bytes"),
      filename: "poster.png",
      content_type: "image/png"
    )
    stored_file = create(:stored_file, root_level: true, user: user, filename: "poster.png", mime_type: "image/png", byte_size: blob.byte_size, active_storage_blob_id: blob.id)

    get drives_file_path(stored_file)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("File detail")
    expect(response.body).to include("poster.png")
    expect(response.body).to include(%(alt="poster.png"))
  end

  it "renders a file detail preview page for text files" do
    user = create(:user)
    login_user(user)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("hello from drive preview"),
      filename: "notes.txt",
      content_type: "text/plain"
    )
    stored_file = create(:stored_file, root_level: true, user: user, filename: "notes.txt", mime_type: "text/plain", byte_size: blob.byte_size, active_storage_blob_id: blob.id)

    get drives_file_path(stored_file)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("notes.txt")
    expect(response.body).to include("hello from drive preview")
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

  it "renders folder options on the file edit page for moving" do
    user = create(:user)
    login_user(user)
    source_folder = create(:folder, user: user, name: "Uploads")
    create(:folder, user: user, name: "Archive")
    stored_file = create(:stored_file, user: user, folder: source_folder, filename: "move-me.txt", mime_type: "text/plain", byte_size: 128)

    get edit_drives_file_path(stored_file)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Folder")
    expect(response.body).to include("Archive")
    expect(response.body).to include("ROOT")
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

  it "creates multiple stored files from direct upload signed ids" do
    user = create(:user)
    login_user(user)
    folder = create(:folder, user: user, name: "Uploads")
    first_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("first drive upload body"),
      filename: "first.txt",
      content_type: "text/plain"
    )
    second_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("second drive upload body"),
      filename: "second.txt",
      content_type: "text/plain"
    )

    expect {
      post drives_files_path, params: {
        stored_file: {
          folder_id: folder.id,
          filename: "",
          source: "local"
        },
        blob_signed_id: [first_blob.signed_id, second_blob.signed_id]
      }
    }.to change { user.stored_files.count }.by(2)

    expect(response).to redirect_to(drives_folder_path(folder))
    expect(flash[:notice]).to eq("2 files uploaded")
    expect(user.stored_files.order(:id).last(2).map(&:filename)).to eq(["first.txt", "second.txt"])
  end

  it "moves a file to a different folder with clear feedback" do
    user = create(:user)
    login_user(user)
    source_folder = create(:folder, user: user, name: "Uploads")
    target_folder = create(:folder, user: user, name: "Archive")
    stored_file = create(:stored_file, user: user, folder: source_folder, filename: "move-me.txt", mime_type: "text/plain", byte_size: 128)

    patch drives_file_path(stored_file), params: {
      stored_file: {
        folder_id: target_folder.id,
        filename: stored_file.filename,
        source: stored_file.source,
        provider: stored_file.provider,
        provider_identifier: stored_file.provider_identifier
      }
    }

    expect(response).to redirect_to(drives_folder_path(target_folder))
    expect(flash[:notice]).to eq("File updated")
    expect(stored_file.reload.folder).to eq(target_folder)
  end

  it "moves a file back to root" do
    user = create(:user)
    login_user(user)
    source_folder = create(:folder, user: user, name: "Uploads")
    stored_file = create(:stored_file, user: user, folder: source_folder, filename: "move-root.txt", mime_type: "text/plain", byte_size: 128)

    patch drives_file_path(stored_file), params: {
      stored_file: {
        folder_id: "",
        filename: stored_file.filename,
        source: stored_file.source,
        provider: stored_file.provider,
        provider_identifier: stored_file.provider_identifier
      }
    }

    expect(response).to redirect_to(drive_path)
    expect(flash[:notice]).to eq("File updated")
    expect(stored_file.reload.folder).to be_nil
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
