module CalendarsHelper
  CALENDAR_COLORS = {
    "cyan" => "border-cyan text-cyan",
    "amber" => "border-amber text-amber",
    "moss" => "border-moss text-moss",
    "signal" => "border-signal text-signal",
    "phosphor" => "border-phosphor text-phosphor"
  }.freeze

  WEEKDAY_OPTIONS = [
    ["Mon", "MO"],
    ["Tue", "TU"],
    ["Wed", "WE"],
    ["Thu", "TH"],
    ["Fri", "FR"],
    ["Sat", "SA"],
    ["Sun", "SU"]
  ].freeze

  def calendar_time_zone_options
    @calendar_time_zone_options ||= ActiveSupport::TimeZone.all.map do |zone|
      [zone.tzinfo.name, zone.to_s]
    end
  end

  def calendar_color_class(calendar)
    CALENDAR_COLORS.fetch(calendar.color, CALENDAR_COLORS["cyan"])
  end

  def calendar_view_link(label, view, current_date:, active:)
    link_to label,
      calendar_path(view:, date: current_date),
      class: token_list(
        "border px-3 py-1 uppercase tracking-widest",
        (active == view) ? "border-amber text-amber glow-amber" : "border-hairline text-phosphor-dim hover:border-phosphor hover:text-phosphor"
      )
  end

  def previous_calendar_date(view_mode, current_date)
    (view_mode == "agenda") ? current_date - 30.days : current_date.prev_month
  end

  def next_calendar_date(view_mode, current_date)
    (view_mode == "agenda") ? current_date + 30.days : current_date.next_month
  end

  def calendar_heading(view_mode, current_date)
    (view_mode == "agenda") ? "Agenda :: #{current_date.strftime("%b %d").upcase}" : current_date.strftime("%B %Y").upcase
  end

  def occurrence_time_label(occurrence)
    return occurrence.starts_at.strftime("%b %d").upcase if occurrence.all_day

    "#{occurrence.starts_at.strftime("%H:%M")} - #{occurrence.ends_at.strftime("%H:%M")}"
  end

  def event_form_value(event, key, fallback = nil)
    event.recurrence_components.fetch(key.to_s.upcase, fallback)
  end

  def event_form_weekdays(event)
    event.recurrence_components.fetch("BYDAY", "").split(",")
  end
end
