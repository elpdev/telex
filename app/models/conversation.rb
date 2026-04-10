class Conversation < ApplicationRecord
  has_many :messages, dependent: :nullify, inverse_of: :conversation
  has_many :outbound_messages, dependent: :nullify, inverse_of: :conversation

  validates :subject_key, presence: true
  validates :last_message_at, presence: true

  def participant_addresses
    super || []
  end

  def timeline_entries
    inbound_entries = messages.includes(inbox: :domain).map do |message|
      {
        kind: :inbound,
        record: message,
        occurred_at: message.received_at || message.created_at,
        sender: message.sender_display,
        recipients: message.to_addresses,
        summary: message.preview_text,
        status: message.status
      }
    end

    outbound_entries = outbound_messages.includes(:domain).map do |message|
      {
        kind: :outbound,
        record: message,
        occurred_at: message.sent_at || message.queued_at || message.created_at,
        sender: message.domain.outbound_from_address.presence || message.domain.name,
        recipients: message.to_addresses,
        summary: message.body_text.squish.presence || "No preview available",
        status: message.status
      }
    end

    (inbound_entries + outbound_entries).sort_by { |entry| [entry[:occurred_at] || Time.at(0), entry[:record].id] }
  end

  def sync_from!(record)
    update!(
      subject_key: record.subject_key,
      participant_addresses: (participant_addresses + record.participant_addresses).uniq.sort,
      last_message_at: [last_message_at, record.occurred_at].compact.max || record.occurred_at
    )
  end
end
