class Calendar < ApplicationRecord
  COLORS = %w[cyan amber moss signal phosphor].freeze

  belongs_to :user
  has_many :calendar_events, dependent: :destroy

  enum :source, {
    local: 0,
    ics_import: 1
  }

  normalizes :name, with: ->(value) { value.to_s.strip }
  normalizes :time_zone, with: ->(value) { value.to_s.strip.presence || Time.zone.tzinfo.name }
  normalizes :color, with: ->(value) { value.to_s.strip.presence || "cyan" }

  validates :name, presence: true
  validates :time_zone, presence: true
  validates :color, presence: true, inclusion: {in: COLORS}

  scope :ordered, -> { order(:position, :name, :id) }

  def upcoming_events(limit: 10)
    calendar_events.where("starts_at >= ?", Time.current).order(:starts_at).limit(limit)
  end
end
