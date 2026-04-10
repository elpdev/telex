module Outbound
  class Sender
    def self.deliver!(outbound_message)
      new(outbound_message).deliver!
    end

    def initialize(outbound_message)
      @outbound_message = outbound_message
    end

    def deliver!
      raise DeliveryError, "Outbound message must have at least one recipient" if outbound_message.to_addresses.blank?

      configuration = DomainConfiguration.resolve!(outbound_message.domain)
      message = OutboundMessagesMailer.with(outbound_message: outbound_message, configuration: configuration).deliver_message.message

      message.deliver

      outbound_message.mark_sent!(mail_message_id: message.message_id)
      message
    end

    private

    attr_reader :outbound_message
  end
end
