module Inbound
  module Processors
    class ExtractCalendarInvitation < Base
      continue_on_error!

      def call
        invite = Calendars::InvitationExtractor.call(message: context.message)
        metadata = context.metadata.deep_dup

        if invite.present?
          metadata["calendar_invitation"] = invite.metadata
          metadata["tags"] = Array(metadata["tags"]) | ["calendar_invitation"]
        else
          metadata.delete("calendar_invitation")
        end

        context.metadata = metadata
      end
    end
  end
end
