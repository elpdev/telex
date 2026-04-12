class DriveAlbum < ApplicationRecord
  belongs_to :user

  has_many :drive_album_memberships, dependent: :destroy
  has_many :stored_files, through: :drive_album_memberships

  normalizes :name, with: ->(value) { value.to_s.strip }

  validates :name, presence: true, uniqueness: {scope: :user_id}

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id name updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[drive_album_memberships stored_files user]
  end
end
