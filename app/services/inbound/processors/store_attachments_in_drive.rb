module Inbound
  module Processors
    class StoreAttachmentsInDrive < Base
      continue_on_error!

      def call
        return unless context.message.attachments.attached?

        target_folder = resolve_target_folder
        return if target_folder.blank?

        context.message.attachments.each do |attachment|
          create_stored_file!(attachment, target_folder)
        end
      end

      private

      def resolve_target_folder
        context.inbox.folder || context.inbox.domain&.folder
      end

      def create_stored_file!(attachment, folder)
        blob = attachment.blob
        return if blob.blank?

        return if StoredFile.exists?(
          user_id: folder.user_id,
          folder_id: folder.id,
          active_storage_blob_id: blob.id,
          source: :message_attachment
        )

        StoredFile.create!(
          user: folder.user,
          folder: folder,
          blob: blob,
          filename: blob.filename.to_s,
          mime_type: blob.content_type,
          byte_size: blob.byte_size,
          source: :message_attachment
        )
      end
    end
  end
end
