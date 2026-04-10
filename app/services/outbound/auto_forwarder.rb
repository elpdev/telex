module Outbound
  class AutoForwarder
    def self.forward_matching!(message)
      new(message).forward_matching!
    end

    def initialize(message)
      @message = message
    end

    def forward_matching!
      message.inbox.matching_forwarding_rules(message).map do |rule|
        outbound_message = ForwardBuilder.create!(
          message,
          target_addresses: rule["target_addresses"],
          rule_name: rule["name"].presence,
          automatic: true
        )
        outbound_message.enqueue_delivery!
      end
    end

    private

    attr_reader :message
  end
end
