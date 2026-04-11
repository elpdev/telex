class API::V1::MeController < API::V1::BaseController
  def show
    render_data(API::V1::Serializers.me(current_user))
  end

  def update
    if current_user.update(me_params)
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
