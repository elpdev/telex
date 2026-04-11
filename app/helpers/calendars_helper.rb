module CalendarsHelper
  TimeGridSegment = Struct.new(
    :occurrence,
    :day,
    :starts_at,
    :ends_at,
    :start_minute,
    :end_minute,
    :lane,
    :lane_count,
    keyword_init: true
  )

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

  def calendar_weekday_options
    WEEKDAY_OPTIONS
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
    case view_mode
    when "agenda"
      current_date - 30.days
    when "week"
      current_date - 1.week
    when "day"
      current_date - 1.day
    else
      current_date.prev_month
    end
  end

  def next_calendar_date(view_mode, current_date)
    case view_mode
    when "agenda"
      current_date + 30.days
    when "week"
      current_date + 1.week
    when "day"
      current_date + 1.day
    else
      current_date.next_month
    end
  end

  def calendar_heading(view_mode, current_date)
    case view_mode
    when "agenda"
      "Agenda :: #{current_date.strftime("%b %d").upcase}"
    when "week"
      week_range = current_date.beginning_of_week..current_date.end_of_week
      "Week :: #{week_range.begin.strftime("%b %d").upcase} - #{week_range.end.strftime("%b %d, %Y").upcase}"
    when "day"
      "Day :: #{current_date.strftime("%a %b %d, %Y").upcase}"
    else
      current_date.strftime("%B %Y").upcase
    end
  end

  def calendar_time_grid_days(view_mode, current_date)
    case view_mode
    when "week"
      (current_date.beginning_of_week..current_date.end_of_week).to_a
    when "day"
      [current_date]
    else
      []
    end
  end

  def calendar_time_grid_segments(occurrences, day)
    timed_segments = occurrences.filter_map do |occurrence|
      next if occurrence.all_day

      segment_for_day(occurrence, day)
    end

    assign_segment_lanes(timed_segments)
  end

  def calendar_all_day_occurrences(occurrences, day)
    occurrences.select do |occurrence|
      occurrence.all_day && occurrence_visible_on_day?(occurrence, day)
    end
  end

  def calendar_hour_labels
    (0..23).map { |hour| Time.zone.local(2000, 1, 1, hour).strftime("%H:00") }
  end

  def calendar_segment_style(segment)
    top = (segment.start_minute / 60.0) * 4
    height = [((segment.end_minute - segment.start_minute) / 60.0) * 4, 1.5].max
    width = 100.0 / segment.lane_count
    left = width * segment.lane

    "top: #{top.round(3)}rem; height: #{height.round(3)}rem; left: #{left.round(3)}%; width: #{width.round(3)}%;"
  end

  def calendar_segment_time_range(segment)
    "#{segment.starts_at.strftime("%H:%M")} - #{segment.ends_at.strftime("%H:%M")}"
  end

  def calendar_day_label(day, condensed: false)
    condensed ? day.strftime("%a %d").upcase : day.strftime("%A %b %d").upcase
  end

  def calendar_day_number_label(day)
    (day == Time.zone.today) ? "#{day.day} TODAY" : day.day.to_s
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

  private

  def occurrence_visible_on_day?(occurrence, day)
    day_start = day.beginning_of_day
    day_end = day.next_day.beginning_of_day

    occurrence.starts_at < day_end && occurrence.ends_at > day_start
  end

  def segment_for_day(occurrence, day)
    day_start = day.beginning_of_day
    day_end = day.next_day.beginning_of_day
    return unless occurrence.starts_at < day_end && occurrence.ends_at > day_start

    starts_at = [occurrence.starts_at, day_start].max
    ends_at = [occurrence.ends_at, day_end].min
    end_minute = ((ends_at - day_start) / 60).ceil.clamp(1, 24 * 60)
    start_minute = ((starts_at - day_start) / 60).floor.clamp(0, (24 * 60) - 1)

    TimeGridSegment.new(
      occurrence: occurrence,
      day: day,
      starts_at: starts_at,
      ends_at: ends_at,
      start_minute: start_minute,
      end_minute: [end_minute, start_minute + 30].max,
      lane: 0,
      lane_count: 1
    )
  end

  def assign_segment_lanes(segments)
    cluster_segments(segments).flat_map do |cluster|
      lanes = []

      cluster.sort_by { |segment| [segment.start_minute, segment.end_minute] }.each do |segment|
        lane_index = lanes.find_index { |lane_end| lane_end <= segment.start_minute }
        lane_index ||= lanes.length
        lanes[lane_index] = segment.end_minute
        segment.lane = lane_index
      end

      lane_count = lanes.length
      cluster.each { |segment| segment.lane_count = lane_count }
    end.sort_by { |segment| [segment.day, segment.start_minute, segment.lane] }
  end

  def cluster_segments(segments)
    sorted = segments.sort_by { |segment| [segment.start_minute, segment.end_minute] }
    clusters = []
    current_cluster = []
    current_end = nil

    sorted.each do |segment|
      if current_end.nil? || segment.start_minute >= current_end
        clusters << current_cluster if current_cluster.any?
        current_cluster = [segment]
        current_end = segment.end_minute
      else
        current_cluster << segment
        current_end = [current_end, segment.end_minute].max
      end
    end

    clusters << current_cluster if current_cluster.any?
    clusters
  end
end
