class OutboundMessagesMailer < ApplicationMailer
  def deliver_message
    @outbound_message = params[:outbound_message]
    @configuration = params[:configuration]

    attach_files
    apply_threading_headers

    mail(
      to: @outbound_message.to_addresses,
      cc: @outbound_message.cc_addresses.presence,
      bcc: @outbound_message.bcc_addresses.presence,
      from: @configuration.from,
      reply_to: @configuration.reply_to,
      subject: @outbound_message.subject,
      delivery_method_options: @configuration.smtp_settings
    ) do |format|
      format.text { render plain: @outbound_message.body_text }
      format.html { render html: @outbound_message.body.to_s.html_safe, layout: false }
    end
  end

  private

  def apply_threading_headers
    headers["In-Reply-To"] = @outbound_message.in_reply_to_message_id if @outbound_message.in_reply_to_message_id.present?
    headers["References"] = @outbound_message.references_header_value if @outbound_message.references_header_value.present?
  end

  def attach_files
    @outbound_message.attachments.each do |attachment|
      attachments[attachment.filename.to_s] = {
        mime_type: attachment.content_type,
        content: attachment.download
      }
    end
  end
end
