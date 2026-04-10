class Domain < ApplicationRecord
  has_many :inboxes, dependent: :destroy, inverse_of: :domain

  normalizes :name, with: ->(value) { value.to_s.strip.downcase }

  validates :name, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[active created_at from_name id name updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[inboxes]
  end
end
