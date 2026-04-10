class Domain < ApplicationRecord
  has_many :inboxes, dependent: :destroy, inverse_of: :domain

  normalizes :name, with: ->(value) { value.to_s.strip.downcase }

  validates :name, presence: true, uniqueness: true
end
