class API::V1::OutboundMessagesController < API::V1::BaseController
  before_action :set_outbound_message, only: [:show, :update, :destroy, :send_message, :queue]

  def index
    scope = OutboundMessage.includes(:domain, :source_message, :conversation).with_attached_attachments.with_rich_text_body
    scope = scope.where(domain_id: params[:domain_id]) if params[:domain_id].present?
    scope = scope.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    scope = scope.where(source_message_id: params[:source_message_id]) if params[:source_message_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = apply_sort(scope, allowed: %w[created_at queued_at sent_at status updated_at], default: :created_at)

    records, meta = paginate(scope)
    render_data(records.map { |outbound_message| API::V1::Serializers.outbound_message(outbound_message) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.outbound_message(@outbound_message))
  end

  def create
    outbound_message = OutboundMessage.new(outbound_message_params)
    outbound_message.body = params.dig(:outbound_message, :body).to_s if params[:outbound_message].present?

    return render_validation_errors(outbound_message) unless outbound_message.save

    enqueue_delivery(outbound_message) if queue_requested?
    render_data(API::V1::Serializers.outbound_message(outbound_message), status: :created)
  end

  def update
    @outbound_message.assign_attributes(outbound_message_params)
    @outbound_message.body = params.dig(:outbound_message, :body).to_s if params[:outbound_message].present? && params[:outbound_message].key?(:body)

    return render_validation_errors(@outbound_message) unless @outbound_message.save

    enqueue_delivery(@outbound_message) if queue_requested?
    render_data(API::V1::Serializers.outbound_message(@outbound_message))
  end

  def destroy
    @outbound_message.destroy!
    head :no_content
  end

  def send_message
    enqueue_delivery(@outbound_message)
    render_data(API::V1::Serializers.outbound_message(@outbound_message.reload))
  rescue ActiveRecord::RecordInvalid
    render_validation_errors(@outbound_message)
  end

  def queue
    send_message
  end

  private

  def set_outbound_message
    @outbound_message = OutboundMessage.includes(:domain, :source_message, :conversation).with_attached_attachments.with_rich_text_body.find(params[:id])
  end

  def enqueue_delivery(outbound_message)
    outbound_message.enqueue_delivery!
  end

  def queue_requested?
    truthy_param?(params[:send_now]) || truthy_param?(params[:queue])
  end

  def outbound_message_params
    params.require(:outbound_message).permit(
      :domain_id,
      :source_message_id,
      :conversation_id,
      :subject,
      :status,
      :in_reply_to_message_id,
      to_addresses: [],
      cc_addresses: [],
      bcc_addresses: [],
      reference_message_ids: [],
      metadata: {}
    )
  end
end
