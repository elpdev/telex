class API::V1::PipelinesController < API::V1::BaseController
  def index
    render_data(Inbound::PipelineRegistry.keys.map { |key| API::V1::Serializers.pipeline(key) })
  end

  def show
    render_data(API::V1::Serializers.pipeline(params[:key]))
  end
end
