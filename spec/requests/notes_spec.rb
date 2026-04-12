require "rails_helper"

RSpec.describe "Notes", type: :request do
  it "renders the notes root page and app navigation" do
    user = create(:user)
    login_user(user)
    notes_root = create(:folder, user: user, name: "Notes", parent: nil)
    create(:folder, user: user, name: "Projects", parent: notes_root)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("# Launch plan\n\nShip it."),
      filename: "Launch plan.md",
      content_type: "text/markdown"
    )
    create(:stored_file,
      user: user,
      folder: notes_root,
      filename: "Launch plan.md",
      mime_type: "text/markdown",
      byte_size: blob.byte_size,
      active_storage_blob_id: blob.id,
      image_width: nil,
      image_height: nil)

    get notes_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("NOTES")
    expect(response.body).to include("Projects")
    expect(response.body).to include("Launch plan")
    expect(response.body).to include('data-node-id="notes"')
    expect(response.body).to include("NTS")
  end

  it "creates the notes root folder on first visit" do
    user = create(:user)
    login_user(user)

    expect {
      get notes_path
    }.to change { user.folders.where(parent_id: nil, name: "Notes").count }.from(0).to(1)

    expect(response).to have_http_status(:ok)
  end

  it "creates a markdown note inside the notes root by default" do
    user = create(:user)
    login_user(user)

    post notes_files_path, params: {
      stored_file: {
        title: "Roadmap",
        body: "# Roadmap\n\n- ship notes"
      }
    }

    note = user.stored_files.order(:id).last

    expect(response).to redirect_to(notes_file_path(note))
    expect(note.filename).to eq("Roadmap.md")
    expect(note.mime_type).to eq("text/markdown")
    expect(note.folder.name).to eq("Notes")
    expect(note.blob.download).to include("# Roadmap")
  end

  it "creates and browses nested notes folders" do
    user = create(:user)
    login_user(user)
    get notes_path
    notes_root = user.folders.find_by!(parent_id: nil, name: "Notes")

    post notes_folders_path, params: {
      folder: {
        name: "Specs",
        parent_id: notes_root.id
      }
    }

    folder = user.folders.order(:id).last

    expect(response).to redirect_to(notes_path)
    expect(folder.parent).to eq(notes_root)

    get notes_folder_path(folder)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("SPECS")
  end

  it "renders the new and edit note pages" do
    user = create(:user)
    login_user(user)
    notes_root = create(:folder, user: user, name: "Notes", parent: nil)
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

    get new_notes_file_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Create markdown note")
    expect(response.body).to include("Preview")

    get edit_notes_file_path(note)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Edit note")
    expect(response.body).to include("Draft")
  end

  it "updates an existing note and re-renders markdown" do
    user = create(:user)
    login_user(user)
    notes_root = create(:folder, user: user, name: "Notes", parent: nil)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("old body"),
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

    patch notes_file_path(note), params: {
      stored_file: {
        title: "Draft v2",
        folder_id: notes_root.id,
        body: "## Updated"
      }
    }

    note.reload

    expect(response).to redirect_to(notes_file_path(note))
    expect(note.filename).to eq("Draft v2.md")
    expect(note.blob.download).to eq("## Updated")

    get notes_file_path(note)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Draft v2")
    expect(response.body).to include("Updated")
  end

  it "renders live preview inside the prose wrapper" do
    user = create(:user)
    login_user(user)

    post notes_preview_path, params: {body: "# Heading"}, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("prose")
    expect(response.body).to include("Heading")
  end
end
