class API::V1::DomainsController < API::V1::BaseController
  before_action :set_domain, only: [:show, :update, :destroy, :outbound_status, :validate_outbound]

  def index
    scope = Domain.all
    scope = scope.where(active: truthy_param?(params[:active])) unless params[:active].nil?
    scope = apply_sort(scope, allowed: %w[created_at name updated_at], default: :name)

    records, meta = paginate(scope)
    render_data(records.map { |domain| API::V1::Serializers.domain(domain) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.domain(@domain))
  end

  def create
    domain = Domain.new(domain_params)

    if domain.save
      render_data(API::V1::Serializers.domain(domain), status: :created)
    else
      render_validation_errors(domain)
    end
  end

  def update
    if @domain.update(domain_params)
      render_data(API::V1::Serializers.domain(@domain))
    else
      render_validation_errors(@domain)
    end
  end

  def destroy
    @domain.destroy!
    head :no_content
  end

  def outbound_status
    render_data({
      id: @domain.id,
      outbound_ready: @domain.outbound_ready?,
      outbound_configuration_errors: @domain.outbound_configuration_errors,
      outbound_identity: @domain.outbound_identity
    })
  end

  def validate_outbound
    domain = @domain
    domain.assign_attributes(domain_params) if params[:domain].present?
    domain.valid?

    render_data({
      valid: domain.errors.empty?,
      outbound_ready: domain.outbound_ready?,
      errors: domain.errors.to_hash(true),
      outbound_configuration_errors: domain.outbound_configuration_errors
    })
  end

  private

  def set_domain
    @domain = Domain.find(params[:id])
  end

  def domain_params
    params.require(:domain).permit(
      :name,
      :active,
      :outbound_from_name,
      :outbound_from_address,
      :use_from_address_for_reply_to,
      :reply_to_address,
      :smtp_host,
      :smtp_port,
      :smtp_authentication,
      :smtp_enable_starttls_auto,
      :smtp_username,
      :smtp_password
    )
  end
end
