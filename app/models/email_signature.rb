class EmailSignature < ApplicationRecord
  belongs_to :domain

  has_rich_text :body

  validates :name, presence: true

  before_save :demote_other_defaults, if: :promoting_to_default?

  scope :default_for, ->(domain) { where(domain: domain, is_default: true) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at domain_id id is_default name updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[domain rich_text_body]
  end

  private

  def promoting_to_default?
    is_default? && (is_default_changed? || new_record?)
  end

  def demote_other_defaults
    EmailSignature
      .where(domain_id: domain_id, is_default: true)
      .where.not(id: id)
      .update_all(is_default: false)
  end
end
