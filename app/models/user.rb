class User < ApplicationRecord
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  has_many :api_keys, class_name: "APIKey", dependent: :destroy
  has_many :outbound_messages, dependent: :nullify

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
end
