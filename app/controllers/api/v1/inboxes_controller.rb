class API::V1::InboxesController < API::V1::BaseController
  before_action :set_inbox, only: [:show, :update, :destroy, :pipeline, :test_forwarding_rules]

  def index
    scope = inbox_scope
    scope = scope.where(domain_id: params[:domain_id]) if params[:domain_id].present?
    scope = scope.where(active: truthy_param?(params[:active])) unless params[:active].nil?
    scope = scope.where(pipeline_key: params[:pipeline_key]) if params[:pipeline_key].present?
    scope = apply_sort(scope, allowed: %w[address created_at local_part updated_at], default: :address)

    records, meta = paginate(scope)
    render_data(records.map { |inbox| API::V1::Serializers.inbox(inbox) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.inbox(@inbox))
  end

  def create
    domain = current_user.domains.find(inbox_params[:domain_id])
    inbox = domain.inboxes.new(inbox_params.except(:domain_id))

    if inbox.save
      render_data(API::V1::Serializers.inbox(inbox), status: :created)
    else
      render_validation_errors(inbox)
    end
  end

  def update
    if @inbox.update(inbox_params)
      render_data(API::V1::Serializers.inbox(@inbox))
    else
      render_validation_errors(@inbox)
    end
  end

  def destroy
    @inbox.destroy!
    head :no_content
  end

  def pipeline
    render_data(API::V1::Serializers.pipeline(@inbox.pipeline_key).merge(overrides: @inbox.pipeline_overrides))
  end

  def test_forwarding_rules
    @inbox.assign_attributes(forwarding_rule_params)
    @inbox.valid?

    render_data({
      valid: @inbox.errors[:forwarding_rules].empty?,
      errors: @inbox.errors[:forwarding_rules],
      forwarding_rules: @inbox.normalized_forwarding_rules
    })
  end

  private

  def set_inbox
    @inbox = inbox_scope.find(params[:id])
  end

  def inbox_scope
    current_user.inboxes.with_message_count_for(user: current_user, count: inbox_count_param)
  end

  def inbox_count_param
    (params[:count].to_s == "all") ? :all : :unread
  end

  def inbox_params
    params.require(:inbox).permit(
      :domain_id,
      :local_part,
      :pipeline_key,
      :description,
      :active,
      pipeline_overrides: {},
      forwarding_rules: [
        :name,
        :active,
        :from_address_pattern,
        :subject_pattern,
        :subaddress_pattern,
        {target_addresses: []}
      ]
    )
  end

  def forwarding_rule_params
    params.require(:inbox).permit(
      forwarding_rules: [
        :name,
        :active,
        :from_address_pattern,
        :subject_pattern,
        :subaddress_pattern,
        {target_addresses: []}
      ]
    )
  end
end
