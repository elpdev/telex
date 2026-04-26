class ContactEmailAddress < ApplicationRecord
  belongs_to :user
  belongs_to :contact

  normalizes :email_address, with: ->(value) { normalize_email(value) }
  normalizes :label, with: ->(value) { value.to_s.strip.presence }

  validates :email_address, presence: true, uniqueness: {scope: :user_id}, format: {with: URI::MailTo::EMAIL_REGEXP}
  validate :contact_belongs_to_same_user

  before_validation :sync_user_from_contact
  before_validation :default_primary_address

  def self.normalize_email(value)
    value.to_s.strip.downcase.presence
  end

  private

  def sync_user_from_contact
    self.user ||= contact&.user
  end

  def default_primary_address
    return unless contact.present?
    return if primary_address? || contact.email_addresses.where.not(id: id).exists?

    self.primary_address = true
  end

  def contact_belongs_to_same_user
    return if contact.blank? || user.blank? || contact.user_id == user_id

    errors.add(:contact_id, "must belong to the same user")
  end
end
