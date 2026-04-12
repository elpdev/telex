class DriveAlbumMembership < ApplicationRecord
  belongs_to :drive_album
  belongs_to :stored_file

  validates :stored_file_id, uniqueness: {scope: :drive_album_id}
  validate :album_and_file_share_owner
  validate :stored_file_is_media

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at drive_album_id id stored_file_id updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[drive_album stored_file]
  end

  private

  def album_and_file_share_owner
    return if drive_album.blank? || stored_file.blank?
    return if drive_album.user_id == stored_file.user_id

    errors.add(:stored_file_id, "must belong to the same user as the album")
  end

  def stored_file_is_media
    return if stored_file.blank? || stored_file.media?

    errors.add(:stored_file_id, "must be an image or video")
  end
end
