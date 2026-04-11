class API::V1::MeController < API::V1::BaseController
  def show
    render_data(API::V1::Serializers.me(current_user))
  end

  def update
    current_user.assign_attributes(me_params)
    current_user.avatar.purge if truthy_param?(params[:remove_avatar]) && current_user.avatar.attached?
    current_user.avatar.attach(params[:user][:avatar]) if params[:user].present? && params[:user][:avatar].present?

    if current_user.save
      render_data(API::V1::Serializers.me(current_user))
    else
      render_validation_errors(current_user)
    end
  end

  private

  def me_params
    params.require(:user).permit(:name, :email_address)
  end
end
