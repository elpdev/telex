module MessageSearchAttachmentCallbacks
  extend ActiveSupport::Concern

  included do
    after_commit :refresh_message_search_index, on: [:create, :destroy]
  end

  private

  def refresh_message_search_index
    record.refresh_search_index! if record.is_a?(Message)
  end
end

Rails.application.config.to_prepare do
  unless ActiveStorage::Attachment.include?(MessageSearchAttachmentCallbacks)
    ActiveStorage::Attachment.include(MessageSearchAttachmentCallbacks)
  end
end
