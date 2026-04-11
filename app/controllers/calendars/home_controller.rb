class Calendars::HomeController < Calendars::BaseController
  VIEW_MODES = %w[month week day agenda].freeze

  def show
    @view_mode = VIEW_MODES.include?(params[:view]) ? params[:view] : "month"
    @current_date = parse_calendar_date(params[:date])
    @calendars = calendars_scope.to_a
    @selected_calendar_ids = selected_calendar_ids(@calendars)
    @selected_calendars = @calendars.select { |calendar| @selected_calendar_ids.include?(calendar.id) }
    @range = calendar_range_for(@view_mode, @current_date)
    @occurrences = Calendars::OccurrencesQuery.call(
      calendars: @selected_calendars,
      range: @range
    )
    @occurrences_by_day = @occurrences.group_by { |occurrence| occurrence.starts_at.to_date }
  end

  private

  def parse_calendar_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    Time.zone.today
  end

  def selected_calendar_ids(calendars)
    ids = Array(params[:calendar_ids]).reject(&:blank?).map(&:to_i)
    ids = calendars.map(&:id) if ids.empty?
    ids
  end

  def calendar_range_for(view_mode, current_date)
    case view_mode
    when "agenda"
      current_date.beginning_of_day..(current_date + 30.days).end_of_day
    when "week"
      current_date.beginning_of_week.beginning_of_day..current_date.end_of_week.end_of_day
    when "day"
      current_date.beginning_of_day..current_date.end_of_day
    else
      current_date.beginning_of_month.beginning_of_week.beginning_of_day..current_date.end_of_month.end_of_week.end_of_day
    end
  end
end
