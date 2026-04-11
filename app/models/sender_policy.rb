class SenderPolicy < ApplicationRecord
  self.table_name = "sender_controls"

  belongs_to :user

  enum :kind, {
    sender: 0,
    domain: 1
  }

  enum :disposition, {
    trusted: 0,
    blocked: 1
  }

  alias_attribute :target_kind, :kind

  normalizes :value, with: ->(value) { value.to_s.strip.downcase }

  validates :value, presence: true, uniqueness: {scope: [:user_id, :kind]}

  def self.set!(user:, target_kind:, value:, disposition:)
    normalized_value = value.to_s.strip.downcase

    find_or_initialize_by(
      user: user,
      kind: target_kind,
      value: normalized_value
    ).tap do |policy|
      policy.disposition = disposition
      policy.save!
    end
  end

  def self.clear!(user:, target_kind:, value:)
    normalized_value = value.to_s.strip.downcase
    where(user: user, kind: target_kind, value: normalized_value).destroy_all
  end

  def matches_message?(message)
    case kind
    when "sender"
      value == message.from_address.to_s.strip.downcase
    when "domain"
      value == message.sender_domain
    else
      false
    end
  end
end
