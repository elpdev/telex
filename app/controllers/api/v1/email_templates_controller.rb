class API::V1::EmailTemplatesController < API::V1::BaseController
  before_action :set_email_template, only: [:show, :update, :destroy]

  def index
    scope = EmailTemplate.includes(:domain).order(:name)
    scope = scope.where(domain_id: params[:domain_id]) if params[:domain_id].present?

    records, meta = paginate(scope)
    render_data(records.map { |email_template| API::V1::Serializers.email_template(email_template) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.email_template(@email_template))
  end

  def create
    email_template = EmailTemplate.new(email_template_params)
    email_template.body = body_param if params[:email_template]&.key?(:body)

    if email_template.save
      render_data(API::V1::Serializers.email_template(email_template), status: :created)
    else
      render_validation_errors(email_template)
    end
  end

  def update
    @email_template.assign_attributes(email_template_params)
    @email_template.body = body_param if params[:email_template]&.key?(:body)

    if @email_template.save
      render_data(API::V1::Serializers.email_template(@email_template))
    else
      render_validation_errors(@email_template)
    end
  end

  def destroy
    @email_template.destroy!
    head :no_content
  end

  private

  def set_email_template
    @email_template = EmailTemplate.find(params[:id])
  end

  def email_template_params
    params.require(:email_template).permit(:domain_id, :name, :subject)
  end

  def body_param
    params.require(:email_template)[:body].to_s
  end
end
