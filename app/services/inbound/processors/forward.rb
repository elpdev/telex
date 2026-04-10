module Inbound
  module Processors
    class Forward < Base
      continue_on_error!

      def call
        forwarded = Outbound::AutoForwarder.forward_matching!(context.message)
        return if forwarded.empty?

        context.metadata["forwarded_message_ids"] = forwarded.map(&:id)
      end
    end
  end
end
