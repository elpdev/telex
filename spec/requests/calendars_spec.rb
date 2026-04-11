require "rails_helper"

RSpec.describe "Calendars", type: :request do
  it "renders the month view from /calendar" do
    user = create(:user)
    login_user(user)
    create(:calendar_event, calendar: user.calendars.first, title: "Launch Review", starts_at: Time.zone.parse("2026-04-15 10:00:00"), ends_at: Time.zone.parse("2026-04-15 11:00:00"))

    get calendar_path, params: {date: "2026-04-15"}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("CALENDAR")
    expect(response.body).to include("Launch Review")
  end

  it "renders the week view from /calendar" do
    user = create(:user)
    login_user(user)
    create(:calendar_event, calendar: user.calendars.first, title: "Design Crit", starts_at: Time.zone.parse("2026-04-15 13:00:00"), ends_at: Time.zone.parse("2026-04-15 14:30:00"))

    get calendar_path, params: {view: "week", date: "2026-04-15"}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Week :: APR 13 - APR 19, 2026")
    expect(response.body).to include("Design Crit")
    expect(response.body).to include("data-controller=\"calendar-time-grid\"")
    expect(response.body).to include("data-local-timestamp-format-value=\"hour\"")
    expect(response.body).to include("data-calendar-time-grid-target=\"timeRange\"")
    expect(response.body).to include("local")
  end

  it "renders overnight events in the day view" do
    user = create(:user)
    login_user(user)
    create(:calendar_event, calendar: user.calendars.first, title: "Night Deploy", starts_at: Time.zone.parse("2026-04-15 23:00:00"), ends_at: Time.zone.parse("2026-04-16 02:00:00"))

    get calendar_path, params: {view: "day", date: "2026-04-16"}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Day :: THU APR 16, 2026")
    expect(response.body).to include("Night Deploy")
    expect(response.body).to include("data-calendar-time-grid-target=\"segment\"")
    expect(response.body).to include("data-calendar-time-grid-target=\"timeRange\"")
    expect(response.body).to include("00:00 - 02:00")
  end

  it "renders the new calendar page" do
    user = create(:user)
    login_user(user)

    get new_calendars_calendar_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("NEW CALENDAR")
    expect(response.body).to include('list="calendar-time-zone-options"')
    expect(response.body).to include("America/New_York")
  end

  it "creates a recurring manual event" do
    user = create(:user)
    login_user(user)

    post calendars_events_path, params: {
      calendar_event: {
        calendar_id: user.calendars.first.id,
        title: "Studio Hours",
        start_date: "2026-04-15",
        end_date: "2026-04-15",
        start_time: "09:00",
        end_time: "10:00",
        time_zone: "UTC",
        status: "confirmed",
        recurrence_frequency: "weekly",
        recurrence_interval: "1",
        recurrence_until: "2026-05-31",
        recurrence_weekdays: ["WE"]
      }
    }

    event = CalendarEvent.order(:id).last

    expect(response).to redirect_to(calendars_event_path(event))
    expect(event.recurrence_rule).to include("FREQ=WEEKLY")
    expect(event.recurrence_rule).to include("BYDAY=WE")
  end

  it "renders the edit event page" do
    user = create(:user)
    login_user(user)
    event = create(:calendar_event, calendar: user.calendars.first, title: "Launch Review")

    get edit_calendars_event_path(event)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("edit event")
    expect(response.body).to include(%(action="#{calendars_event_path(event)}"))
  end

  it "imports an ics file into the selected calendar" do
    user = create(:user)
    login_user(user)

    post calendars_imports_path, params: {
      import: {
        calendar_id: user.calendars.first.id,
        file: fixture_file_upload("calendar/recurring_import.ics", "text/calendar")
      }
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Import summary")
    expect(user.calendars.first.calendar_events.find_by(uid: "weekly-sync-1")).to be_present
  end

  it "creates a second calendar" do
    user = create(:user)
    login_user(user)

    post calendars_calendars_path, params: {
      calendar: {
        name: "Launches",
        color: "amber",
        time_zone: "UTC",
        position: 1
      }
    }

    expect(response).to redirect_to(calendars_calendars_path)
    expect(user.calendars.order(:id).last.name).to eq("Launches")
  end
end
