module Outbound
  class ForwardBuilder
    def self.create!(message, target_addresses:, rule_name: nil, automatic: false, user: nil)
      new(message, target_addresses:, rule_name:, automatic:, user:).create!
    end

    def initialize(message, target_addresses:, rule_name: nil, automatic: false, user: nil)
      @message = message
      @target_addresses = normalize_addresses(target_addresses)
      @rule_name = rule_name
      @automatic = automatic
      @user = user
    end

    def create!
      outbound_message = message.inbox.domain.outbound_messages.new(
        source_message: message,
        to_addresses: target_addresses,
        subject: forward_subject,
        user: user,
        metadata: {
          "draft_kind" => "forward",
          "automatic_forward" => automatic,
          "forwarding_rule_name" => rule_name
        }.compact
      )

      outbound_message.body = forward_body
      outbound_message.save!
      copy_attachments_to(outbound_message)
      outbound_message
    end

    private

    attr_reader :message, :target_addresses, :rule_name, :automatic, :user

    def normalize_addresses(values)
      Array(values).filter_map do |value|
        normalized = value.to_s.strip.downcase
        normalized.presence
      end.uniq
    end

    def forward_subject
      source_subject = message.subject.to_s.strip
      source_subject = "(no subject)" if source_subject.blank?
      return source_subject if source_subject.match?(/\Afwd:/i)

      "Fwd: #{source_subject}"
    end

    def forward_body
      <<~BODY

        ---------- Forwarded message ----------
        From: #{forward_from_line}
        Date: #{I18n.l(message.received_at, format: :long)}
        Subject: #{message.subject.presence || "(no subject)"}
        To: #{Array(message.to_addresses).join(", ").presence || "No To recipients"}
        Cc: #{Array(message.cc_addresses).join(", ").presence || "No Cc recipients"}

        #{message.text_body.to_s.presence || message.body.to_plain_text}
      BODY
    end

    def forward_from_line
      return message.from_address if message.from_name.blank?

      "#{message.from_name} (#{message.from_address})"
    end

    def copy_attachments_to(outbound_message)
      message.attachments.each do |attachment|
        outbound_message.attachments.attach(
          io: StringIO.new(attachment.download),
          filename: attachment.filename.to_s,
          content_type: attachment.content_type
        )
      end
    end
  end
end
