class FallbackMailbox < ApplicationMailbox
  def process
    recipients = [mail.to, mail.cc, mail.bcc].flatten.compact.uniq

    Rails.logger.warn(
      event: "inbound_mail_fallback",
      inbound_email_id: inbound_email.id,
      recipients: recipients
    )
  rescue => error
    Rails.logger.error(
      event: "inbound_mail_fallback_error",
      inbound_email_id: inbound_email.id,
      error: error.message
    )
  ensure
    Inbound::Router.clear(inbound_email)
  end
end
