module Inbound
  module Processors
    class Forward < Base
      continue_on_error!

      def call
        return if blocked_message?

        forwarded = Outbound::AutoForwarder.forward_matching!(context.message)
        return if forwarded.empty?

        context.metadata["forwarded_message_ids"] = forwarded.map(&:id)
      end

      private

      def blocked_message?
        context.metadata.dig("sender_policies", "blocked_user_ids").present?
      end
    end
  end
end
