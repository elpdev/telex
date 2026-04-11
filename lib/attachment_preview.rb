module AttachmentPreview
  module_function

  IMAGE_EXTENSIONS = %w[jpg jpeg png gif webp bmp svg tif tiff].freeze

  def preview_kind(attachment)
    content_type = attachment.content_type.to_s.downcase
    extension = attachment.filename.extension_without_delimiter.to_s.downcase

    return :image if content_type.start_with?("image/") || IMAGE_EXTENSIONS.include?(extension)
    return :pdf if content_type == "application/pdf" || extension == "pdf"

    :unsupported
  end

  def previewable?(attachment)
    preview_kind(attachment) != :unsupported
  end

  def display_content_type(attachment)
    attachment.content_type.presence || "attachment"
  end
end
