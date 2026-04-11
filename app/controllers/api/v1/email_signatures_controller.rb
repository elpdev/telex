class API::V1::EmailSignaturesController < API::V1::BaseController
  before_action :set_email_signature, only: [:show, :update, :destroy]

  def index
    scope = EmailSignature.includes(:domain).order(:name)
    scope = scope.where(domain_id: params[:domain_id]) if params[:domain_id].present?

    records, meta = paginate(scope)
    render_data(records.map { |email_signature| API::V1::Serializers.email_signature(email_signature) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.email_signature(@email_signature))
  end

  def create
    email_signature = EmailSignature.new(email_signature_params)
    email_signature.body = body_param if params[:email_signature]&.key?(:body)

    if email_signature.save
      render_data(API::V1::Serializers.email_signature(email_signature), status: :created)
    else
      render_validation_errors(email_signature)
    end
  end

  def update
    @email_signature.assign_attributes(email_signature_params)
    @email_signature.body = body_param if params[:email_signature]&.key?(:body)

    if @email_signature.save
      render_data(API::V1::Serializers.email_signature(@email_signature))
    else
      render_validation_errors(@email_signature)
    end
  end

  def destroy
    @email_signature.destroy!
    head :no_content
  end

  private

  def set_email_signature
    @email_signature = EmailSignature.find(params[:id])
  end

  def email_signature_params
    params.require(:email_signature).permit(:domain_id, :name, :is_default)
  end

  def body_param
    params.require(:email_signature)[:body].to_s
  end
end
