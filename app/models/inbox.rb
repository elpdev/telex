class Inbox < ApplicationRecord
  belongs_to :domain
  has_many :messages, dependent: :destroy, inverse_of: :inbox

  normalizes :local_part, with: ->(value) { value.to_s.strip.downcase }
  normalizes :address, with: ->(value) { value.to_s.strip.downcase }
  normalizes :pipeline_key, with: ->(value) { value.to_s.strip }

  validates :local_part, presence: true
  validates :address, presence: true, uniqueness: true
  validates :pipeline_key, presence: true
  validates :local_part, uniqueness: {scope: :domain_id}

  scope :active, -> { where(active: true) }

  before_validation :sync_address
  validate :pipeline_key_registered

  def pipeline
    Inbound::PipelineRegistry.fetch(pipeline_key)
  end

  def pipeline_overrides
    super || {}
  end

  def message_count
    self[:message_count] || 0
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[active address created_at description domain_id id local_part pipeline_key updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[domain messages]
  end

  private

  def sync_address
    return if local_part.blank? || domain.nil? || domain.name.blank?

    self.address = "#{local_part}@#{domain.name}".downcase
  end

  def pipeline_key_registered
    return if pipeline_key.blank?
    return if Inbound::PipelineRegistry::PIPELINES.key?(pipeline_key)

    errors.add(:pipeline_key, "is not registered")
  end
end
