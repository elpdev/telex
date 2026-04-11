require "rails_helper"

RSpec.describe Calendars::IcsImporter do
  it "imports recurring and all-day events from an ics file" do
    calendar = create(:calendar)

    result = described_class.call(
      calendar: calendar,
      file: fixture_file_upload("calendar/recurring_import.ics", "text/calendar")
    )

    expect(result).to be_success
    expect(result.created).to eq(2)
    expect(calendar.calendar_events.count).to eq(2)

    recurring = calendar.calendar_events.find_by(uid: "weekly-sync-1")
    all_day = calendar.calendar_events.find_by(uid: "offsite-1")

    expect(recurring.recurrence_rule).to include("FREQ=WEEKLY")
    expect(recurring.recurrence_rule).to include("BYDAY=TU")
    expect(recurring.recurrence_rule).to include("COUNT=4")
    expect(recurring.recurrence_exceptions).not_to be_empty
    expect(all_day).to be_all_day
  end

  it "updates an existing event with the same uid" do
    calendar = create(:calendar)
    create(:calendar_event, calendar: calendar, uid: "weekly-sync-1", title: "Old title")

    result = described_class.call(
      calendar: calendar,
      file: fixture_file_upload("calendar/recurring_import.ics", "text/calendar")
    )

    expect(result.updated).to eq(1)
    expect(calendar.calendar_events.find_by(uid: "weekly-sync-1").title).to eq("Weekly Sync")
  end
end
