module Outbound
  class ReplyBuilder
    def self.create!(message, reply_all: false, user: nil)
      new(message, reply_all: reply_all, user: user).create!
    end

    def initialize(message, reply_all: false, user: nil)
      @message = message
      @reply_all = reply_all
      @user = user
    end

    def create!
      outbound_message = message.inbox.domain.outbound_messages.new(
        source_message: message,
        to_addresses: to_addresses,
        cc_addresses: cc_addresses,
        subject: reply_subject,
        user: user,
        in_reply_to_message_id: normalized_message_id(message.message_id),
        reference_message_ids: reply_reference_message_ids,
        metadata: {reply_all: reply_all}
      )

      outbound_message.body = ""
      outbound_message.save!
      outbound_message
    end

    private

    attr_reader :message, :reply_all, :user

    def to_addresses
      addresses = [message.from_address]
      addresses.concat(filtered_original_to_addresses) if reply_all
      normalize_addresses(addresses)
    end

    def cc_addresses
      return [] unless reply_all

      normalize_addresses(message.cc_addresses.reject { |address| excluded_addresses.include?(address.to_s.downcase) || to_addresses.include?(address.to_s.downcase) })
    end

    def filtered_original_to_addresses
      message.to_addresses.reject { |address| excluded_addresses.include?(address.to_s.downcase) || address.to_s.strip.casecmp?(message.from_address.to_s.strip) }
    end

    def excluded_addresses
      @excluded_addresses ||= [message.inbox.address.to_s.downcase]
    end

    def normalize_addresses(values)
      Array(values).filter_map do |value|
        normalized = value.to_s.strip.downcase
        normalized.presence
      end.uniq
    end

    def reply_subject
      source_subject = message.subject.to_s.strip
      source_subject = "(no subject)" if source_subject.blank?
      return source_subject if source_subject.match?(/\Are:/i)

      "Re: #{source_subject}"
    end

    def reply_reference_message_ids
      ids = message.inbound_email.mail.header["References"]&.value.to_s.scan(/<[^>]+>/)
      ids << normalized_message_id(message.message_id)
      ids.compact.uniq
    end

    def normalized_message_id(value)
      stripped = value.to_s.strip
      return if stripped.blank?

      return stripped if stripped.start_with?("<") && stripped.end_with?(">")

      "<#{stripped}>"
    end
  end
end
