module Inbound
  module Processors
    class Notify < Base
      continue_on_error!

      def call
        recipient = resolve_recipient
        return if recipient.nil?

        Inbound::MessageReceivedNotifier.with(message: context.message).deliver(recipient)
      end

      private

      def resolve_recipient
        override_id = context.inbox.pipeline_overrides["notify_user_id"]
        User.find_by(id: override_id) || User.where(admin: true).first
      end
    end
  end
end
