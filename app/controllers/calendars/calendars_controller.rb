class Calendars::CalendarsController < Calendars::BaseController
  before_action :set_calendar, only: [:edit, :update]
  before_action :set_calendars, only: [:index, :new, :create, :edit, :update]

  def index
  end

  def new
    @calendar = Current.user.calendars.new(color: "cyan", time_zone: Time.zone.tzinfo.name)
  end

  def create
    @calendar = Current.user.calendars.new(calendar_params.merge(source: :local))

    if @calendar.save
      redirect_to calendars_calendars_path, notice: "Calendar created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @calendar.update(calendar_params)
      redirect_to calendars_calendars_path, notice: "Calendar updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_calendars
    @calendars = calendars_scope.to_a
  end

  def set_calendar
    @calendar = calendars_scope.find(params[:id])
  end

  def calendar_params
    params.require(:calendar).permit(:name, :color, :time_zone, :position)
  end
end
