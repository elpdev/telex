require "rails_helper"

RSpec.describe DriveAlbumMembership, type: :model do
  it "allows a media file to belong to many albums" do
    user = create(:user)
    stored_file = create(:stored_file, root_level: true, user: user, mime_type: "image/png")
    first_album = create(:drive_album, user: user)
    second_album = create(:drive_album, user: user)

    create(:drive_album_membership, drive_album: first_album, stored_file: stored_file)
    membership = build(:drive_album_membership, drive_album: second_album, stored_file: stored_file)

    expect(membership).to be_valid
  end

  it "rejects memberships for files owned by another user" do
    album = create(:drive_album)
    stored_file = create(:stored_file, root_level: true)
    membership = build(:drive_album_membership, drive_album: album, stored_file: stored_file)

    expect(membership).not_to be_valid
    expect(membership.errors[:stored_file_id]).to include("must belong to the same user as the album")
  end

  it "rejects non-media files" do
    album = create(:drive_album)
    stored_file = create(:stored_file, root_level: true, user: album.user, mime_type: "text/plain")
    membership = build(:drive_album_membership, drive_album: album, stored_file: stored_file)

    expect(membership).not_to be_valid
    expect(membership.errors[:stored_file_id]).to include("must be an image or video")
  end
end
