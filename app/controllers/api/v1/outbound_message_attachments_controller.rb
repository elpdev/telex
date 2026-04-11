class API::V1::OutboundMessageAttachmentsController < API::V1::BaseController
  include AttachmentDelivery

  before_action :set_outbound_message
  before_action :set_attachment, only: [:show, :download, :destroy]

  def index
    render_data(@outbound_message.attachments.map { |attachment| API::V1::Serializers.attachment_payload(attachment, parent: @outbound_message, api: true) })
  end

  def show
    send_attachment(@attachment, disposition: AttachmentPreview.previewable?(@attachment) ? :inline : :attachment)
  end

  def download
    send_attachment(@attachment, disposition: :attachment)
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
      @outbound_message.attachments.reload.map { |attachment| API::V1::Serializers.attachment_payload(attachment, parent: @outbound_message, api: true) },
      status: :created
    )
  end

  def destroy
    @attachment.purge
    head :no_content
  end

  private

  def set_outbound_message
    @outbound_message = current_user.outbound_messages.with_attached_attachments.find(params[:outbound_message_id])
  end

  def set_attachment
    @attachment = @outbound_message.attachments.find(params[:id])
  end
end
