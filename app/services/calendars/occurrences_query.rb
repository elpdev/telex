class Calendars::OccurrencesQuery
  Occurrence = Struct.new(:event, :starts_at, :ends_at, :all_day, keyword_init: true)

  def self.call(calendars:, range:)
    new(calendars:, range:).call
  end

  def initialize(calendars:, range:)
    @calendars = Array(calendars)
    @range = range
  end

  def call
    @calendars.flat_map do |calendar|
      calendar.calendar_events.chronological.filter_map do |event|
        next if event.cancelled?

        occurrences_for(event)
      end
    end.flatten.compact.sort_by(&:starts_at)
  end

  private

  def occurrences_for(event)
    if event.recurring?
      event.schedule.occurrences_between(@range.begin, @range.end).map do |start_time|
        Occurrence.new(
          event: event,
          starts_at: start_time,
          ends_at: start_time + event.duration_seconds,
          all_day: event.all_day
        )
      end
    elsif event.ends_at >= @range.begin && event.starts_at <= @range.end
      Occurrence.new(event: event, starts_at: event.starts_at, ends_at: event.ends_at, all_day: event.all_day)
    end
  end
end
