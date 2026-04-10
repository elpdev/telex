module Conversations
  class Resolver
    def self.assign!(record)
      new(record).assign!
    end

    def initialize(record)
      @record = record
    end

    def assign!
      conversation = source_conversation || header_matched_conversation || subject_fallback_conversation || build_conversation
      record.update!(conversation: conversation) unless record.conversation == conversation
      conversation.sync_from!(record)
      conversation
    end

    private

    attr_reader :record

    def source_conversation
      return unless record.is_a?(OutboundMessage)
      return if record.metadata["draft_kind"] == "forward"

      record.source_message&.conversation
    end

    def header_matched_conversation
      ids = referenced_message_ids
      return if ids.blank?

      Message.where(message_id: ids).where.not(conversation_id: nil).order(received_at: :desc, id: :desc).pick(:conversation_id)&.yield_self { |id| Conversation.find_by(id: id) } ||
        OutboundMessage.where(mail_message_id: ids).where.not(conversation_id: nil).order(sent_at: :desc, id: :desc).pick(:conversation_id)&.yield_self { |id| Conversation.find_by(id: id) }
    end

    def subject_fallback_conversation
      candidates = Conversation.where(subject_key: record.subject_key).order(last_message_at: :desc).limit(10)
      candidates.find do |conversation|
        (conversation.participant_addresses & record.participant_addresses).any?
      end
    end

    def build_conversation
      Conversation.create!(
        subject_key: record.subject_key,
        participant_addresses: record.participant_addresses,
        last_message_at: record.occurred_at
      )
    end

    def referenced_message_ids
      ids = []
      ids << record.in_reply_to_message_id if record.respond_to?(:in_reply_to_message_id)
      ids.concat(record.reference_message_ids) if record.respond_to?(:reference_message_ids)
      ids.filter_map { |value| normalize_message_id(value) }.uniq
    end

    def normalize_message_id(value)
      stripped = value.to_s.strip
      return if stripped.blank?

      return stripped if stripped.start_with?("<") && stripped.end_with?(">")

      "<#{stripped}>"
    end
  end
end
