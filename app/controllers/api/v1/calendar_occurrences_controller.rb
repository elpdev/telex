class API::V1::CalendarOccurrencesController < API::V1::BaseController
  def index
    calendars = current_user.calendars.ordered
    calendars = calendars.where(id: params[:calendar_id]) if params[:calendar_id].present?
    calendars = calendars.where(id: params[:calendar_ids]) if params[:calendar_ids].present?

    occurrences = Calendars::OccurrencesQuery.call(calendars: calendars, range: range)
    render_data(occurrences.map { |occurrence| API::V1::Serializers.calendar_occurrence(occurrence, current_user: current_user) })
  end

  private

  def range
    start_time = params[:starts_from].present? ? Time.zone.parse(params[:starts_from]) : Time.zone.now.beginning_of_day
    end_time = params[:ends_to].present? ? Time.zone.parse(params[:ends_to]) : 30.days.from_now.end_of_day
    start_time..end_time
  end
end
