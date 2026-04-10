module Inbound
  class Ingestor
    class << self
      def ingest!(inbound_email, inbox:, subaddress: nil)
        new(inbound_email, inbox: inbox, subaddress: subaddress).ingest!
      end
    end

    def initialize(inbound_email, inbox:, subaddress: nil)
      @inbound_email = inbound_email
      @inbox = inbox
      @subaddress = subaddress
      @mail = inbound_email.mail
    end

    def ingest!
      Message.transaction do
        message = Message.find_or_initialize_by(inbox: inbox, inbound_email: inbound_email)
        return message if message.persisted?

        from = extract_from_address
        message.assign_attributes(
          message_id: mail.message_id,
          from_address: from&.address,
          from_name: from&.display_name,
          to_addresses: Array(mail.to).compact,
          cc_addresses: Array(mail.cc).compact,
          subject: mail.subject,
          subaddress: subaddress,
          received_at: mail.date || Time.current,
          text_body: extract_text_body,
          status: :received,
          metadata: {}
        )
        message.save!

        message.body = build_body_content
        attach_files(message)
        message.save!
        message
      end
    rescue ActiveRecord::RecordNotUnique
      Message.find_by!(inbox: inbox, inbound_email: inbound_email)
    end

    private

    attr_reader :inbound_email, :inbox, :subaddress, :mail

    def extract_text_body
      if mail.multipart?
        mail.text_part&.decoded.presence || text_from_html(extract_html_body) || mail.body.decoded
      elsif mail.mime_type.to_s.include?("html")
        text_from_html(mail.body.decoded)
      else
        mail.body.decoded
      end
    end

    def extract_html_body
      if mail.multipart?
        mail.html_part&.decoded.presence
      elsif mail.mime_type.to_s.include?("html")
        mail.body.decoded
      end
    end

    def build_body_content
      html_body = extract_html_body
      return ActionController::Base.helpers.sanitize(html_body) if html_body.present?

      "<pre>#{ERB::Util.html_escape(extract_text_body.to_s)}</pre>"
    end

    def text_from_html(html)
      return if html.blank?

      ActionView::Base.full_sanitizer.sanitize(html).presence
    end

    def attach_files(message)
      mail.all_parts.select(&:attachment?).each do |part|
        next if part.filename.blank?

        message.attachments.attach(
          io: StringIO.new(part.body.decoded),
          filename: part.filename,
          content_type: part.mime_type
        )
      end
    end

    def extract_from_address
      raw_from = mail[:from]&.value.presence || Array(mail.from).first
      return if raw_from.blank?

      Mail::Address.new(raw_from)
    rescue Mail::Field::ParseError
      nil
    end
  end
end
