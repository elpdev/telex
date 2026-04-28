class API::V1::CalendarEventsController < API::V1::BaseController
  before_action :set_calendar_event, only: [:show, :update, :destroy, :messages]

  def index
    scope = CalendarEvent.includes(:calendar_event_attendees, :calendar_event_links).joins(:calendar).where(calendars: {user_id: current_user.id})
    scope = scope.where(calendar_id: params[:calendar_id]) if params[:calendar_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(source: params[:source]) if params[:source].present?
    scope = scope.where(uid: params[:uid]) if params[:uid].present?
    scope = scope.where("calendar_events.starts_at >= ?", parse_time(params[:starts_from])) if params[:starts_from].present?
    scope = scope.where("calendar_events.ends_at <= ?", parse_time(params[:ends_to])) if params[:ends_to].present?
    scope = apply_updated_since(scope)
    scope = apply_sort(scope, allowed: %w[created_at ends_at starts_at status title updated_at], default: :starts_at)

    records, meta = paginate(scope)
    render_data(records.map { |event| API::V1::Serializers.calendar_event(event, current_user: current_user) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.calendar_event(@calendar_event, include_messages: true, current_user: current_user))
  end

  def create
    calendar = current_user.calendars.find(event_params.fetch(:calendar_id))
    calendar_event = calendar.calendar_events.new(base_event_attributes)

    if calendar_event.save
      render_data(API::V1::Serializers.calendar_event(calendar_event, include_messages: true, current_user: current_user), status: :created)
    else
      render_validation_errors(calendar_event)
    end
  end

  def update
    @calendar_event.assign_attributes(base_event_attributes)

    if @calendar_event.save
      render_data(API::V1::Serializers.calendar_event(@calendar_event, include_messages: true, current_user: current_user))
    else
      render_validation_errors(@calendar_event)
    end
  end

  def destroy
    @calendar_event.destroy!
    head :no_content
  end

  def messages
    render_data(@calendar_event.invitation_messages.map { |message| API::V1::Serializers.message_summary(message, current_user: current_user) })
  end

  private

  def set_calendar_event
    @calendar_event = CalendarEvent.includes(:calendar, :calendar_event_attendees, :calendar_event_links, messages: :inbox).joins(:calendar).where(calendars: {user_id: current_user.id}).find(params[:id])
  end

  def event_params
    params.require(:calendar_event).permit(
      :calendar_id,
      :title,
      :description,
      :location,
      :all_day,
      :start_date,
      :end_date,
      :start_time,
      :end_time,
      :time_zone,
      :status,
      :recurrence_frequency,
      :recurrence_interval,
      :recurrence_until,
      recurrence_weekdays: []
    )
  end

  def base_event_attributes
    parsed = Calendars::EventParamsParser.call(event_params)
    parsed.except(:calendar_id).merge(
      source: @calendar_event&.source || :manual,
      recurrence_rule: Calendars::RecurrenceRuleBuilder.call(parsed, event_params.to_h),
      recurrence_exceptions: @calendar_event&.recurrence_exceptions || []
    )
  end

  def parse_time(value)
    Time.zone.parse(value)
  end
end
