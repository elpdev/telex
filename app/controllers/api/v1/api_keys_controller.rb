class API::V1::APIKeysController < API::V1::BaseController
  before_action :set_api_key, only: [:show, :update, :destroy]

  def index
    scope = current_user.api_keys.order(created_at: :desc)
    records, meta = paginate(scope)

    render_data(records.map { |api_key| API::V1::Serializers.api_key(api_key) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.api_key(@api_key))
  end

  def create
    api_key = current_user.api_keys.build(api_key_params)
    secret_key = SecureRandom.hex(32)
    api_key.secret_key = secret_key

    if api_key.save
      render_data(API::V1::Serializers.api_key(api_key, secret_key: secret_key), status: :created)
    else
      render_validation_errors(api_key)
    end
  end

  def update
    if @api_key.update(api_key_params)
      render_data(API::V1::Serializers.api_key(@api_key))
    else
      render_validation_errors(@api_key)
    end
  end

  def destroy
    @api_key.destroy!
    head :no_content
  end

  private

  def set_api_key
    @api_key = current_user.api_keys.find(params[:id])
  end

  def api_key_params
    params.require(:api_key).permit(:name, :expires_at)
  end
end
