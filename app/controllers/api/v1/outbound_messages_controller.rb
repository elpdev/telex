class API::V1::OutboundMessagesController < API::V1::BaseController
  before_action :set_outbound_message, only: [:show, :update, :destroy, :insert_template, :send_message, :queue]

  def index
    scope = current_user.outbound_messages.includes(:domain, :source_message, :conversation).with_attached_attachments.with_rich_text_body
    scope = scope.where(domain_id: params[:domain_id]) if params[:domain_id].present?
    scope = scope.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    scope = scope.where(source_message_id: params[:source_message_id]) if params[:source_message_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = apply_updated_since(scope)
    scope = apply_sort(scope, allowed: %w[created_at queued_at sent_at status updated_at], default: :created_at)

    records, meta = paginate(scope)
    render_data(records.map { |outbound_message| API::V1::Serializers.outbound_message(outbound_message) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.outbound_message(@outbound_message))
  end

  def create
    outbound_message = current_user.outbound_messages.new(outbound_message_params)
    assign_api_body(outbound_message) if params[:outbound_message].present?

    return render_validation_errors(outbound_message) unless outbound_message.save

    enqueue_delivery(outbound_message) if queue_requested?
    render_data(API::V1::Serializers.outbound_message(outbound_message), status: :created)
  end

  def compose
    domain = compose_domain
    return render_error("No active inbox domain available", status: :unprocessable_content) if domain.blank?

    outbound_message = current_user.outbound_messages.new(domain: domain, inbox: compose_inbox, metadata: {"draft_kind" => "compose"})
    outbound_message.body = Outbound::SignatureInjector.call(domain: domain)
    outbound_message.save!

    render_data(API::V1::Serializers.outbound_message(outbound_message), status: :created)
  end

  def update
    @outbound_message.assign_attributes(outbound_message_params)
    assign_api_body(@outbound_message) if params[:outbound_message].present? && params[:outbound_message].key?(:body)

    return render_validation_errors(@outbound_message) unless @outbound_message.save

    enqueue_delivery(@outbound_message) if queue_requested?
    render_data(API::V1::Serializers.outbound_message(@outbound_message))
  end

  def destroy
    @outbound_message.destroy!
    head :no_content
  end

  def insert_template
    template = @outbound_message.domain.email_templates.find_by(id: params[:template_id] || params[:insert_template_id])
    return render_error("Template not found", status: :not_found) if template.blank?

    existing_body = @outbound_message.body.to_s
    @outbound_message.body = template.body.to_s + existing_body
    @outbound_message.subject = template.subject if @outbound_message.subject.blank? && template.subject.present?
    @outbound_message.save!

    render_data(API::V1::Serializers.outbound_message(@outbound_message))
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
    @outbound_message = current_user.outbound_messages.includes(:domain, :source_message, :conversation).with_attached_attachments.with_rich_text_body.find(params[:id])
  end

  def enqueue_delivery(outbound_message)
    outbound_message.enqueue_delivery!
  end

  def assign_api_body(outbound_message)
    body = params.dig(:outbound_message, :body).to_s
    outbound_message.body = html_body?(body) ? body : helpers.simple_format(body)
  end

  def html_body?(body)
    body.match?(/<\s*(a|blockquote|br|div|h[1-6]|li|ol|p|pre|span|strong|em|table|tbody|td|th|thead|tr|ul)\b/i)
  end

  def queue_requested?
    truthy_param?(params[:send_now]) || truthy_param?(params[:queue])
  end

  def outbound_message_params
    params.require(:outbound_message).permit(
      :domain_id,
      :inbox_id,
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

  def compose_domain
    return current_user.domains.find_by(id: params[:domain_id]) if params[:domain_id].present?

    compose_inbox&.domain || current_user.inboxes.active.includes(:domain).order(:address).first&.domain
  end

  def compose_inbox
    return @compose_inbox if defined?(@compose_inbox)

    @compose_inbox = current_user.inboxes.active.find_by(id: params[:inbox_id]) if params[:inbox_id].present?
  end
end
