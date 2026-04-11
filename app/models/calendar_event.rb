class CalendarEvent < ApplicationRecord
  belongs_to :calendar

  enum :source, {
    manual: 0,
    ics_import: 1
  }

  enum :status, {
    confirmed: 0,
    tentative: 1,
    cancelled: 2
  }

  serialize :recurrence_exceptions, coder: JSON, type: Array

  normalizes :title, with: ->(value) { value.to_s.strip }
  normalizes :location, with: ->(value) { value.to_s.strip.presence }
  normalizes :organizer_name, with: ->(value) { value.to_s.strip.presence }
  normalizes :organizer_email, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :time_zone, with: ->(value) { value.to_s.strip.presence }

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :uid, uniqueness: {scope: :calendar_id}, allow_blank: true
  validate :ends_after_start

  scope :chronological, -> { order(:starts_at, :id) }

  def recurring?
    recurrence_rule.present?
  end

  def effective_time_zone
    time_zone.presence || calendar.time_zone.presence || Time.zone.tzinfo.name
  end

  def duration_seconds
    [ends_at - starts_at, 0].max.to_i
  end

  def schedule
    start_time = starts_at.in_time_zone(effective_time_zone)
    end_time = ends_at.in_time_zone(effective_time_zone)
    schedule = IceCube::Schedule.new(start_time, end_time: end_time)
    schedule.add_recurrence_rule(IceCube::Rule.from_ical(recurrence_rule)) if recurring?
    recurrence_exception_times.each { |time| schedule.add_exception_time(time) }
    schedule
  rescue ArgumentError
    IceCube::Schedule.new(start_time || starts_at, end_time: end_time || ends_at)
  end

  def recurrence_exception_times
    Array(recurrence_exceptions).filter_map do |value|
      next if value.blank?

      time = Time.iso8601(value)
      time.in_time_zone(effective_time_zone)
    rescue ArgumentError
      nil
    end
  end

  def recurrence_components
    recurrence_rule.to_s.split(";").each_with_object({}) do |part, result|
      key, value = part.split("=", 2)
      result[key] = value if key.present? && value.present?
    end
  end

  def recurrence_summary
    return "Does not repeat" unless recurring?

    IceCube::Rule.from_ical(recurrence_rule).to_s
  rescue ArgumentError
    recurrence_rule
  end

  def next_occurrences(limit: 6, from: Time.current)
    return [] if cancelled?

    if recurring?
      schedule.next_occurrences(limit, from.in_time_zone(effective_time_zone))
    elsif starts_at >= from
      [starts_at]
    else
      []
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[all_day calendar_id created_at description ends_at id location organizer_email organizer_name raw_payload recurrence_rule source starts_at status time_zone title uid updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[calendar]
  end

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank?
    return if ends_at >= starts_at

    errors.add(:ends_at, "must be after the start time")
  end
end
