class API::V1::HealthController < ActionController::API
  def show
    render json: {data: {status: "ok"}}
  end
end
