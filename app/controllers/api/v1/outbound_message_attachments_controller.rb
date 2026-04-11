class API::V1::OutboundMessageAttachmentsController < API::V1::BaseController
  before_action :set_outbound_message

  def index
    render_data(@outbound_message.attachments.map { |attachment| API::V1::Serializers.attachment_payload(attachment) })
  end

  def create
    files = Array(params[:attachments] || params[:files]).compact
    files << params[:attachment] if params[:attachment].present?
    files << params[:file] if params[:file].present?

    return render_error("No attachments provided", status: :bad_request) if files.empty?

    files.each do |file|
      @outbound_message.attachments.attach(file)
    end

    render_data(
      @outbound_message.attachments.reload.map { |attachment| API::V1::Serializers.attachment_payload(attachment) },
      status: :created
    )
  end

  def destroy
    attachment = @outbound_message.attachments_attachments.includes(:blob).find(params[:id])
    attachment.purge
    head :no_content
  end

  private

  def set_outbound_message
    @outbound_message = OutboundMessage.with_attached_attachments.find(params[:outbound_message_id])
  end
end
