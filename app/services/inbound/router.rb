module Inbound
  class Router
    Match = Struct.new(:inbox, :recipient, :subaddress, keyword_init: true)

    HEADER_RECIPIENTS = ["X-Original-To", "Delivered-To"].freeze

    class << self
      def match?(inbound_email)
        match(inbound_email).present?
      end

      def match(inbound_email)
        cache.fetch(cache_key(inbound_email)) do
          find_match(inbound_email)
        end
      end

      def clear(inbound_email)
        cache.delete(cache_key(inbound_email))
      end

      private

      def find_match(inbound_email)
        recipients_for(inbound_email.mail).each do |recipient|
          recipient_candidates(recipient).each do |normalized, subaddress|
            next if normalized.blank?

            inbox = Inbox.active.find_by(address: normalized)
            next if inbox.nil?

            return Match.new(inbox: inbox, recipient: recipient, subaddress: subaddress)
          end
        end

        nil
      end

      def recipients_for(mail)
        header_recipients = mail.header.fields.select { |field| HEADER_RECIPIENTS.include?(field.name) }.flat_map do |field|
          Mail::AddressList.new(field.value.to_s).addresses.map(&:address)
        rescue Mail::Field::ParseError
          field.value.to_s.split(/[\s,]+/)
        end

        [mail.to, mail.cc, mail.bcc, header_recipients].flatten.compact.map(&:downcase).uniq
      end

      def recipient_candidates(recipient)
        parsed = Mail::Address.new(recipient)
        local_part = parsed.local.to_s.downcase
        domain = parsed.domain.to_s.downcase

        exact_address = ["#{local_part}@#{domain}", nil]
        plus_address = tagged_address(local_part, domain, separator: "+")
        dot_address = tagged_address(local_part, domain, separator: ".")

        [exact_address, plus_address, dot_address].compact.uniq
      rescue Mail::Field::ParseError
        []
      end

      def tagged_address(local_part, domain, separator:)
        base, subaddress = local_part.rpartition(separator).values_at(0, 2)
        return if base.blank? || subaddress.blank?

        ["#{base}@#{domain}", subaddress]
      end

      def cache
        Thread.current[:inbound_router_cache] ||= {}
      end

      def cache_key(inbound_email)
        inbound_email.id || inbound_email.message_id || inbound_email.object_id
      end
    end
  end
end
