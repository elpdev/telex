class ContactCommunication < ApplicationRecord
  belongs_to :user
  belongs_to :contact
  belongs_to :communicable, polymorphic: true

  validates :occurred_at, presence: true
  validates :communicable_id, uniqueness: {scope: [:contact_id, :communicable_type]}
  validate :contact_belongs_to_same_user

  before_validation :sync_user_from_contact

  def metadata
    value = super
    value.is_a?(Hash) ? value : {}
  end

  private

  def sync_user_from_contact
    self.user ||= contact&.user
  end

  def contact_belongs_to_same_user
    return if contact.blank? || user.blank? || contact.user_id == user_id

    errors.add(:contact_id, "must belong to the same user")
  end
end
