class StoredFile < ApplicationRecord
  belongs_to :user
  belongs_to :folder, optional: true
  belongs_to :blob, class_name: "ActiveStorage::Blob", foreign_key: :active_storage_blob_id, optional: true

  enum :source, {
    local: 0,
    provider: 1,
    message_attachment: 2
  }

  normalizes :filename, with: ->(value) { value.to_s.strip }
  normalizes :mime_type, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :provider, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :provider_identifier, with: ->(value) { value.to_s.strip.presence }

  before_validation :sync_blob_metadata

  validates :filename, presence: true
  validates :provider_identifier, uniqueness: {scope: [:user_id, :provider]}, allow_blank: true
  validate :folder_belongs_to_same_user

  def metadata
    value = super
    value.is_a?(Hash) ? value : {}
  end

  def image?
    mime_type.to_s.start_with?("image/")
  end

  def image_metadata
    return {} unless image_width.present? || image_height.present?

    {
      width: image_width,
      height: image_height
    }.compact
  end

  def local_blob?
    blob.present?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[active_storage_blob_id byte_size created_at filename folder_id id image_height image_width mime_type provider provider_created_at provider_identifier provider_updated_at source updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[blob folder user]
  end

  private

  def folder_belongs_to_same_user
    return if folder.blank? || folder.user_id == user_id

    errors.add(:folder_id, "must belong to the same user")
  end

  def sync_blob_metadata
    return if blob.blank?

    self.filename = blob.filename.to_s if filename.blank?
    self.mime_type = blob.content_type if mime_type.blank?
    self.byte_size = blob.byte_size if byte_size.blank?

    blob_metadata = blob.metadata.is_a?(Hash) ? blob.metadata : {}
    self.image_width ||= blob_metadata["width"]
    self.image_height ||= blob_metadata["height"]
  end
end
