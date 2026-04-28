class API::V1::CalendarsController < API::V1::BaseController
  before_action :set_calendar, only: [:show, :update, :destroy, :import_ics]

  def index
    scope = current_user.calendars.ordered
    scope = apply_updated_since(scope)
    records, meta = paginate(scope)
    render_data(records.map { |calendar| API::V1::Serializers.calendar(calendar) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.calendar(@calendar))
  end

  def create
    calendar = current_user.calendars.new(calendar_params)

    if calendar.save
      render_data(API::V1::Serializers.calendar(calendar), status: :created)
    else
      render_validation_errors(calendar)
    end
  end

  def update
    if @calendar.update(calendar_params)
      render_data(API::V1::Serializers.calendar(@calendar))
    else
      render_validation_errors(@calendar)
    end
  end

  def destroy
    @calendar.destroy!
    head :no_content
  end

  def import_ics
    file = params[:file] || params.dig(:import, :file)
    return render_error("File is required", status: :bad_request) if file.blank?

    result = Calendars::IcsImporter.call(calendar: @calendar, file: file)
    render_data({
      created: result.created,
      updated: result.updated,
      skipped: result.skipped,
      failed: result.failed,
      errors: result.errors,
      success: result.success?
    }, status: result.success? ? :ok : :unprocessable_content)
  end

  private

  def set_calendar
    @calendar = current_user.calendars.find(params[:id])
  end

  def calendar_params
    params.require(:calendar).permit(:name, :color, :time_zone, :position)
  end
end
