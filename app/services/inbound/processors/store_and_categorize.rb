module Inbound
  module Processors
    class StoreAndCategorize < Base
      def call
        metadata = context.metadata.deep_dup
        metadata["tags"] ||= []

        metadata["tags"] << "subaddressed" if context.subaddress.present?
        metadata["tags"] << "has_attachments" if context.message.attachments.attached?
        metadata["tags"] << "from_admin" if context.message.from_address.to_s.ends_with?("@#{context.inbox.domain.name}")

        metadata["tags"] = metadata["tags"].uniq.sort
        context.metadata = metadata
      end
    end
  end
end
