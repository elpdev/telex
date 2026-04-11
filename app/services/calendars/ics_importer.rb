class Calendars::IcsImporter
  def self.call(calendar:, file:)
    new(calendar:, file:).call
  end

  def initialize(calendar:, file:)
    @calendar = calendar
    @file = file
  end

  def call
    created = 0
    updated = 0
    skipped = 0
    failed = 0
    errors = []

    Icalendar::Calendar.parse(@file.read).each do |parsed_calendar|
      parsed_calendar.events.each do |event|
        attrs = event_attributes(event)
        if attrs.nil?
          skipped += 1
          next
        end

        record = attrs[:uid].present? ? @calendar.calendar_events.find_or_initialize_by(uid: attrs[:uid]) : @calendar.calendar_events.new
        created += 1 if record.new_record?
        updated += 1 unless record.new_record?
        record.assign_attributes(attrs)
        record.save!
      rescue => error
        failed += 1
        errors << error.message
      end
    end

    Calendars::ImportResult.new(created:, updated:, skipped:, failed:, errors:)
  rescue => error
    Calendars::ImportResult.new(created: 0, updated: 0, skipped: 0, failed: 1, errors: [error.message])
  end

  private

  def event_attributes(event)
    starts_at = convert_time(event.dtstart)
    return if starts_at.blank?

    ends_at = convert_end_time(event.dtend, all_day_event?(event), starts_at)

    {
      title: event.summary.to_s.presence || "Untitled event",
      description: event.description.to_s.presence,
      location: event.location.to_s.presence,
      starts_at: starts_at,
      ends_at: ends_at,
      all_day: all_day_event?(event),
      time_zone: time_zone_for(event),
      status: normalized_status(event.status),
      organizer_name: Array(event.organizer&.ical_params&.[]("cn")).first,
      organizer_email: event.organizer.to_s.delete_prefix("mailto:").presence,
      source: :ics_import,
      uid: event.uid.to_s.presence,
      raw_payload: event.to_ical,
      recurrence_rule: Array(event.rrule).first&.value_ical.to_s.presence,
      recurrence_exceptions: Array(event.exdate).flat_map { |value| Array(value).map { |entry| convert_time(entry)&.utc&.iso8601 } }.compact,
      sequence_number: event.sequence.to_i,
      last_imported_at: Time.current,
      calendar: @calendar
    }
  end

  def convert_time(value)
    raw = value&.to_time
    return if raw.blank?

    raw.in_time_zone(time_zone_for_value(value))
  end

  def convert_end_time(value, all_day, starts_at)
    return starts_at.end_of_day if all_day && value.blank?
    return starts_at + 1.hour if value.blank?

    converted = convert_time(value)
    return converted unless all_day

    (converted - 1.second).end_of_day
  end

  def all_day_event?(event)
    event.dtstart.is_a?(Date) || event.dtstart&.value.is_a?(Date)
  end

  def time_zone_for(event)
    time_zone_for_value(event.dtstart) || @calendar.time_zone
  end

  def time_zone_for_value(value)
    Array(value&.ical_params&.[]("tzid")).first.presence || @calendar.time_zone
  end

  def normalized_status(status)
    normalized = status.to_s.downcase
    return :tentative if normalized == "tentative"
    return :cancelled if normalized == "cancelled"

    :confirmed
  end
end
