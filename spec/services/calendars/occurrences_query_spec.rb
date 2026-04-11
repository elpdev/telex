require "rails_helper"

RSpec.describe Calendars::OccurrencesQuery do
  it "expands recurring events and respects exception times" do
    calendar = create(:calendar)
    event = create(
      :calendar_event,
      :weekly,
      calendar: calendar,
      starts_at: Time.zone.parse("2026-04-15 10:00:00"),
      ends_at: Time.zone.parse("2026-04-15 11:00:00"),
      recurrence_exceptions: [Time.zone.parse("2026-04-29 10:00:00").utc.iso8601]
    )

    occurrences = described_class.call(
      calendars: [calendar],
      range: Time.zone.parse("2026-04-01 00:00:00")..Time.zone.parse("2026-05-31 23:59:59")
    )

    expect(occurrences.map(&:event)).to all(eq(event))
    expect(occurrences.map { |occurrence| occurrence.starts_at.to_date }).to eq([
      Date.new(2026, 4, 15),
      Date.new(2026, 4, 22),
      Date.new(2026, 5, 6)
    ])
  end
end
