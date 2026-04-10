class DeliverOutboundMessageJob < ApplicationJob
  MAX_ATTEMPTS = 5

  queue_as :outbound

  def perform(outbound_message)
    return if outbound_message.sent?

    outbound_message.increment!(:delivery_attempts)
    outbound_message.mark_sending!
    Outbound::Sender.deliver!(outbound_message)
  rescue Outbound::ConfigurationError, Outbound::DeliveryError => error
    outbound_message.mark_failed!(error)
  rescue => error
    if outbound_message.delivery_attempts >= MAX_ATTEMPTS
      outbound_message.mark_failed!(error)
    else
      retry_job
    end
  end
end
