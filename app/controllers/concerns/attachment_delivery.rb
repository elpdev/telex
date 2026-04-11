module AttachmentDelivery
  extend ActiveSupport::Concern

  private

  def send_attachment(attachment, disposition:)
    send_data(
      attachment.download,
      filename: attachment.filename.to_s,
      type: attachment.content_type.presence || "application/octet-stream",
      disposition: disposition
    )
  end

  def send_blob(blob, filename:, content_type:, disposition:)
    send_data(
      blob.download,
      filename: filename,
      type: content_type.presence || "application/octet-stream",
      disposition: disposition
    )
  end
end
