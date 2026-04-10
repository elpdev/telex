module Inbound
  class MessageReceivedNotifier < Noticed::Event
    notification_methods do
      def message
        record = params[:message]
        "New message for #{record.inbox.address}: #{record.subject.presence || "(no subject)"}"
      end

      def url
        madmin_message_path(params[:message])
      end
    end
  end
end
