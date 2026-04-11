class EmailTemplate < ApplicationRecord
  belongs_to :domain

  has_rich_text :body

  validates :name, presence: true, uniqueness: {scope: :domain_id}

  scope :alphabetical, -> { order(Arel.sql("LOWER(name)")) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at domain_id id name subject updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[domain rich_text_body]
  end
end
