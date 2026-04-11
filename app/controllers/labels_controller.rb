class LabelsController < ApplicationController
  def create
    label = Current.user.labels.build(label_params)

    if label.save
      redirect_back fallback_location: root_path
    else
      redirect_back fallback_location: root_path, alert: label.errors.full_messages.to_sentence
    end
  end

  def destroy
    label = Current.user.labels.find(params[:id])
    label.destroy!

    redirect_back fallback_location: root_path
  end

  private

  def label_params
    params.require(:label).permit(:name, :color)
  end
end
