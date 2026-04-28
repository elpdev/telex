class API::V1::BaseController < ActionController::API
  before_action :authenticate_with_jwt!

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def authenticate_with_jwt!
    token = request.authorization.to_s.delete_prefix("Bearer ").presence
    return render_unauthorized unless token

    payload = JWTService.decode(token)
    return render_unauthorized unless payload

    @current_user = User.find_by(id: payload["user_id"])
    @current_api_key = APIKey.find_by(id: payload["api_key_id"])

    render_unauthorized unless @current_user
  end

  attr_reader :current_user

  attr_reader :current_api_key

  def render_unauthorized
    render json: {error: "Unauthorized"}, status: :unauthorized
  end

  def render_not_found(error)
    render json: {error: error.message}, status: :not_found
  end

  def render_bad_request(error)
    render json: {error: error.message}, status: :bad_request
  end

  def render_error(message, status: :unprocessable_content)
    render json: {error: message}, status: status
  end

  def render_validation_errors(record)
    render json: {
      error: "Validation failed",
      details: record.errors.to_hash(true)
    }, status: :unprocessable_content
  end

  def render_data(data, status: :ok, meta: nil)
    payload = {data: data}
    payload[:meta] = meta if meta.present?
    render json: payload, status: status
  end

  def paginate(scope)
    page = [params.fetch(:page, 1).to_i, 1].max
    per_page = params.fetch(:per_page, 25).to_i
    per_page = 25 if per_page <= 0
    per_page = [per_page, 100].min
    total_count = scope.except(:limit, :offset).unscope(:order, :select).count
    total_count = total_count.size if total_count.is_a?(Hash)

    [
      scope.limit(per_page).offset((page - 1) * per_page),
      {page: page, per_page: per_page, total_count: total_count}
    ]
  end

  def apply_updated_since(scope, column: nil)
    return scope if params[:updated_since].blank?

    timestamp = parse_timestamp_param(params[:updated_since])
    column ||= "#{scope.klass.quoted_table_name}.updated_at"
    scope.where("#{column} >= ?", timestamp)
  end

  def parse_timestamp_param(value)
    Time.zone.parse(value.to_s) || raise(ArgumentError)
  rescue ArgumentError
    raise ActionController::BadRequest, "Invalid updated_since timestamp"
  end

  def apply_sort(scope, allowed:, default:)
    sort_value = params[:sort].to_s
    direction = sort_value.start_with?("-") ? :desc : :asc
    key = sort_value.delete_prefix("-")
    key = default.to_s if key.blank? || !allowed.include?(key)

    scope.order(key => direction)
  end

  def truthy_param?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
