class Calendars::ImportsController < Calendars::BaseController
  def new
    @calendars = calendars_scope.to_a
  end

  def create
    @calendars = calendars_scope.to_a
    calendar = calendars_scope.find(params.require(:import).fetch(:calendar_id))
    file = params.require(:import).fetch(:file)
    @result = Calendars::IcsImporter.call(calendar:, file:)
    flash.now[@result.success? ? :notice : :alert] = @result.message
    render :new, status: (@result.success? ? :ok : :unprocessable_entity)
  rescue ActionController::ParameterMissing, ActiveRecord::RecordNotFound => error
    @result = Calendars::ImportResult.new(created: 0, updated: 0, skipped: 0, failed: 1, errors: [error.message])
    flash.now[:alert] = @result.message
    render :new, status: :unprocessable_entity
  end
end
