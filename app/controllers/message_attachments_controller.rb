class MessageAttachmentsController < ApplicationController
  include AttachmentDelivery

  before_action :set_message
  before_action :set_attachment

  def show
    send_attachment(@attachment, disposition: AttachmentPreview.previewable?(@attachment) ? :inline : :attachment)
  end

  def download
    send_attachment(@attachment, disposition: :attachment)
  end

  private

  def set_message
    @message = Message.joins(inbox: :domain).where(domains: {user_id: Current.user.id}).with_attached_attachments.find(params[:message_id])
  end

  def set_attachment
    @attachment = @message.attachments.find(params[:id])
  end
end
