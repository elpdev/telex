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
        mapped = Calendars::IcalendarEventMapper.call(
          event: event,
          fallback_time_zone: @calendar.time_zone,
          source: :ics_import
        )

        if mapped.nil?
          skipped += 1
          next
        end

        attrs = mapped[:event_attributes].merge(calendar: @calendar)
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
end
