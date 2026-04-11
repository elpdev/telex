class API::V1::SenderPoliciesController < API::V1::BaseController
  before_action :set_sender_policy, only: [:show, :update, :destroy]

  def index
    scope = current_user.sender_policies
    scope = scope.where(kind: params[:kind]) if params[:kind].present?
    scope = scope.where(disposition: params[:disposition]) if params[:disposition].present?
    scope = apply_sort(scope, allowed: %w[created_at disposition kind updated_at value], default: :value)

    records, meta = paginate(scope)
    render_data(records.map { |sender_policy| API::V1::Serializers.sender_policy(sender_policy) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.sender_policy(@sender_policy))
  end

  def create
    sender_policy = current_user.sender_policies.build(sender_policy_params)

    if sender_policy.save
      render_data(API::V1::Serializers.sender_policy(sender_policy), status: :created)
    else
      render_validation_errors(sender_policy)
    end
  end

  def update
    if @sender_policy.update(sender_policy_params)
      render_data(API::V1::Serializers.sender_policy(@sender_policy))
    else
      render_validation_errors(@sender_policy)
    end
  end

  def destroy
    @sender_policy.destroy!
    head :no_content
  end

  private

  def set_sender_policy
    @sender_policy = current_user.sender_policies.find(params[:id])
  end

  def sender_policy_params
    params.require(:sender_policy).permit(:kind, :disposition, :value)
  end
end
