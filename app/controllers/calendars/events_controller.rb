class Calendars::EventsController < Calendars::BaseController
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :set_calendars, only: [:show, :new, :create, :edit, :update]

  def show
    @next_occurrences = @event.next_occurrences(limit: 8)
    @invitation_links = @event.calendar_event_links.includes(message: :inbox).order(created_at: :desc)
  end

  def new
    default_calendar = calendars_scope.first
    @event = CalendarEvent.new(
      calendar: default_calendar,
      starts_at: Time.zone.now.change(min: 0) + 1.hour,
      ends_at: Time.zone.now.change(min: 0) + 2.hours,
      time_zone: default_calendar&.time_zone || Time.zone.tzinfo.name,
      source: :manual,
      status: :confirmed
    )
  end

  def create
    @event = Current.user.calendars.find(event_params[:calendar_id]).calendar_events.new(base_event_attributes)

    if @event.save
      redirect_to calendars_event_path(@event), notice: "Event created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(base_event_attributes)
      redirect_to calendars_event_path(@event), notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy!
    redirect_to calendar_path, notice: "Event deleted."
  end

  private

  def set_event
    @event = CalendarEvent.joins(:calendar).merge(calendars_scope).find(params[:id])
  end

  def set_calendars
    @calendars = calendars_scope.to_a
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
    parsed.merge(
      source: @event&.source || :manual,
      recurrence_rule: Calendars::RecurrenceRuleBuilder.call(parsed, event_params.to_h),
      recurrence_exceptions: @event&.recurrence_exceptions || []
    )
  end
end
