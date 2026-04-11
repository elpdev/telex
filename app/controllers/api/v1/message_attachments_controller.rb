class API::V1::MessageAttachmentsController < API::V1::BaseController
  before_action :set_message

  def index
    render_data(@message.attachments.map { |attachment| API::V1::Serializers.attachment_payload(attachment) })
  end

  def show
    attachment = @message.attachments_attachments.includes(:blob).find(params[:id])
    send_data attachment.download, filename: attachment.filename.to_s, type: attachment.content_type, disposition: :inline
  end

  private

  def set_message
    @message = Message.with_attached_attachments.find(params[:message_id])
  end
end
