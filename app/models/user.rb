class User < ApplicationRecord
  has_one_attached :avatar

  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  has_many :api_keys, class_name: "APIKey", dependent: :destroy
  has_many :labels, dependent: :destroy
  has_many :message_organizations, dependent: :destroy
  has_many :conversation_organizations, dependent: :destroy
  has_many :sender_policies, dependent: :destroy
  has_many :outbound_messages, dependent: :nullify
  has_many :calendars, dependent: :destroy

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}

  validate :avatar_must_be_an_image

  after_create :create_default_calendar!

  private

  def avatar_must_be_an_image
    return unless avatar.attached?
    return if avatar.content_type.to_s.start_with?("image/")

    errors.add(:avatar, "must be an image")
  end

  def create_default_calendar!
    calendars.create!(
      name: "Personal",
      color: "cyan",
      time_zone: Time.zone.tzinfo.name,
      source: :local,
      position: 0
    )
  end
end
