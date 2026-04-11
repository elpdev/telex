module AttachmentPreviewsHelper
  def attachment_preview_kind(attachment)
    AttachmentPreview.preview_kind(attachment)
  end

  def attachment_previewable?(attachment)
    AttachmentPreview.previewable?(attachment)
  end

  def attachment_display_content_type(attachment)
    AttachmentPreview.display_content_type(attachment)
  end
end
