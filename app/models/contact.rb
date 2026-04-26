class Contact < ApplicationRecord
  belongs_to :user
  belongs_to :note_file, class_name: "StoredFile", optional: true

  has_many :email_addresses, class_name: "ContactEmailAddress", dependent: :destroy, inverse_of: :contact
  has_many :contact_communications, dependent: :destroy
  has_many :messages, dependent: :nullify

  enum :contact_type, {
    person: 0,
    business: 1
  }

  normalizes :name, with: ->(value) { value.to_s.strip.presence }
  normalizes :company_name, with: ->(value) { value.to_s.strip.presence }
  normalizes :title, with: ->(value) { value.to_s.strip.presence }
  normalizes :phone, with: ->(value) { value.to_s.strip.presence }
  normalizes :website, with: ->(value) { value.to_s.strip.presence }

  validates :contact_type, presence: true
  validate :note_file_belongs_to_same_user

  scope :ordered, -> { order(Arel.sql("LOWER(COALESCE(contacts.name, contacts.company_name, '')) ASC"), id: :asc) }

  def self.find_or_create_for_email!(user:, email_address:, name: nil)
    normalized = ContactEmailAddress.normalize_email(email_address)
    return if normalized.blank?

    existing_email = ContactEmailAddress.includes(:contact).find_by(user: user, email_address: normalized)
    if existing_email.present?
      existing_email.contact.tap do |contact|
        contact.update!(name: name) if contact.name.blank? && name.present?
      end
    else
      create!(user: user, contact_type: :person, name: name.presence || normalized).tap do |contact|
        contact.email_addresses.create!(user: user, email_address: normalized, label: "email", primary_address: true)
      end
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def metadata
    value = super
    value.is_a?(Hash) ? value : {}
  end

  def primary_email_address
    email_addresses.find(&:primary_address?) || email_addresses.first
  end

  def display_name
    name.presence || company_name.presence || primary_email_address&.email_address || "Unnamed contact"
  end

  private

  def note_file_belongs_to_same_user
    return if note_file.blank? || note_file.user_id == user_id

    errors.add(:note_file_id, "must belong to the same user")
  end
end
