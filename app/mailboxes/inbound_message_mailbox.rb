class InboundMessageMailbox < ApplicationMailbox
  def process
    match = Inbound::Router.match(inbound_email)
    return if match.nil?

    message = Inbound::Ingestor.ingest!(inbound_email, inbox: match.inbox, subaddress: match.subaddress)
    ProcessMessageJob.perform_later(message)
  ensure
    Inbound::Router.clear(inbound_email)
  end
end
