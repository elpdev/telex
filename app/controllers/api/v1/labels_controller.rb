class API::V1::LabelsController < API::V1::BaseController
  before_action :set_label, only: [:show, :update, :destroy]

  def index
    render_data(current_user.labels.order(:name).map { |label| API::V1::Serializers.label(label) })
  end

  def show
    render_data(API::V1::Serializers.label(@label))
  end

  def create
    label = current_user.labels.build(label_params)

    if label.save
      render_data(API::V1::Serializers.label(label), status: :created)
    else
      render_validation_errors(label)
    end
  end

  def update
    if @label.update(label_params)
      render_data(API::V1::Serializers.label(@label))
    else
      render_validation_errors(@label)
    end
  end

  def destroy
    @label.destroy!
    head :no_content
  end

  private

  def set_label
    @label = current_user.labels.find(params[:id])
  end

  def label_params
    params.require(:label).permit(:name, :color)
  end
end
