module Outbound
  class DomainConfiguration
    Result = Struct.new(:domain, :from, :reply_to, :smtp_settings, keyword_init: true)

    def self.resolve!(domain, inbox: nil)
      new(domain, inbox: inbox).resolve!
    end

    def initialize(domain, inbox: nil)
      @domain = domain
      @inbox = inbox
    end

    def resolve!
      raise_invalid_configuration unless domain.outbound_ready?

      Result.new(
        domain: domain,
        from: formatted_from,
        reply_to: domain.resolved_reply_to_address,
        smtp_settings: domain.smtp_delivery_settings
      )
    end

    private

    attr_reader :domain, :inbox

    def formatted_from
      return domain.formatted_outbound_from if inbox.blank?

      address = Mail::Address.new(inbox.address)
      address.display_name = domain.outbound_from_name
      address.format
    end

    def raise_invalid_configuration
      Rails.logger.error(error_message)
      raise ConfigurationError, error_message
    end

    def error_message
      "Outbound delivery is unavailable for domain #{domain.name}: #{domain.outbound_configuration_errors.join(", ")}"
    end
  end
end
