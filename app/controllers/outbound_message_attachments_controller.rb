class OutboundMessageAttachmentsController < ApplicationController
  include AttachmentDelivery

  before_action :set_outbound_message
  before_action :set_attachment

  def show
    send_attachment(@attachment, disposition: AttachmentPreview.previewable?(@attachment) ? :inline : :attachment)
  end

  def download
    send_attachment(@attachment, disposition: :attachment)
  end

  private

  def set_outbound_message
    @outbound_message = Current.user.outbound_messages.with_attached_attachments.find(params[:outbound_message_id])
  end

  def set_attachment
    @attachment = @outbound_message.attachments.find(params[:id])
  end
end
