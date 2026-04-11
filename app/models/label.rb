class Label < ApplicationRecord
  belongs_to :user

  has_many :message_labelings, dependent: :destroy
  has_many :message_organizations, through: :message_labelings
  has_many :conversation_labelings, dependent: :destroy
  has_many :conversation_organizations, through: :conversation_labelings

  normalizes :name, with: ->(value) { value.to_s.strip }

  validates :name, presence: true, uniqueness: {scope: :user_id}

  def self.ransackable_attributes(_auth_object = nil)
    %w[color created_at id name updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[conversation_labelings conversation_organizations message_labelings message_organizations user]
  end
end
