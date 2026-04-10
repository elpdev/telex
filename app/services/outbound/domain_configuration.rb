module Outbound
  class DomainConfiguration
    Result = Struct.new(:domain, :from, :reply_to, :smtp_settings, keyword_init: true)

    def self.resolve!(domain)
      new(domain).resolve!
    end

    def initialize(domain)
      @domain = domain
    end

    def resolve!
      raise_invalid_configuration unless domain.outbound_ready?

      Result.new(
        domain: domain,
        from: domain.formatted_outbound_from,
        reply_to: domain.resolved_reply_to_address,
        smtp_settings: domain.smtp_delivery_settings
      )
    end

    private

    attr_reader :domain

    def raise_invalid_configuration
      Rails.logger.error(error_message)
      raise ConfigurationError, error_message
    end

    def error_message
      "Outbound delivery is unavailable for domain #{domain.name}: #{domain.outbound_configuration_errors.join(", ")}"
    end
  end
end
