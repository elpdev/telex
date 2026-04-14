class Folder < ApplicationRecord
  belongs_to :user
  belongs_to :parent, class_name: "Folder", optional: true

  has_many :children, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :stored_files, dependent: :destroy
  has_many :domains, foreign_key: :drive_folder_id, dependent: :nullify, inverse_of: :drive_folder
  has_many :inboxes, foreign_key: :drive_folder_id, dependent: :nullify, inverse_of: :drive_folder

  enum :source, {
    local: 0,
    provider: 1,
    message_attachment: 2
  }

  normalizes :name, with: ->(value) { value.to_s.strip }
  normalizes :provider, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :provider_identifier, with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true
  validates :name, uniqueness: {scope: [:user_id, :parent_id]}
  validates :provider_identifier, uniqueness: {scope: [:user_id, :provider]}, allow_blank: true
  validate :parent_belongs_to_same_user
  validate :parent_cannot_be_self_or_descendant

  def metadata
    value = super
    value.is_a?(Hash) ? value : {}
  end

  def root?
    parent_id.nil?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id name parent_id provider provider_identifier source updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[children domains inboxes parent stored_files user]
  end

  private

  def parent_belongs_to_same_user
    return if parent.blank? || parent.user_id == user_id

    errors.add(:parent_id, "must belong to the same user")
  end

  def parent_cannot_be_self_or_descendant
    return if parent.blank?
    return errors.add(:parent_id, "cannot be self") if parent_id == id

    ancestor = parent
    while ancestor.present?
      if ancestor.id == id
        errors.add(:parent_id, "cannot create a cycle")
        break
      end

      ancestor = ancestor.parent
    end
  end
end
