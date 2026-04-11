class Conversation < ApplicationRecord
  has_many :messages, dependent: :nullify, inverse_of: :conversation
  has_many :outbound_messages, dependent: :nullify, inverse_of: :conversation
  has_many :conversation_organizations, dependent: :destroy
  has_many :conversation_labelings, through: :conversation_organizations
  has_many :labels, through: :conversation_organizations

  validates :subject_key, presence: true
  validates :last_message_at, presence: true

  def self.in_mailbox_for(user, mailbox)
    mailbox = mailbox.to_s.presence || "inbox"

    case mailbox
    when "archived", "trash"
      joins(organization_join_sql(user, join_type: "INNER JOIN"))
        .where(conversation_organizations: {system_state: ConversationOrganization.system_states.fetch(mailbox)})
    else
      joins(organization_join_sql(user))
        .where("conversation_organizations.id IS NULL OR conversation_organizations.system_state = ?", ConversationOrganization.system_states.fetch("inbox"))
    end
  end

  def self.with_label_for(user, label_id)
    return all if label_id.blank?

    where(
      id: ConversationOrganization.joins(:conversation_labelings)
        .where(user: user, conversation_labelings: {label_id: label_id})
        .select(:conversation_id)
    )
  end

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

  def organization_for(user)
    return if user.blank?

    conversation_organizations.find { |organization| organization.user_id == user.id } || conversation_organizations.find_by(user: user)
  end

  def ensure_organization_for(user)
    ConversationOrganization.for(user, self)
  end

  def effective_system_state_for(user)
    organization_for(user)&.system_state || "inbox"
  end

  def labels_for(user)
    organization_for(user)&.labels&.sort_by(&:name) || []
  end

  def move_to_state_for(user, system_state)
    ensure_organization_for(user).update!(system_state: system_state)
  end

  def assign_labels_for(user, label_ids)
    organization = ensure_organization_for(user)
    labels = user.labels.where(id: Array(label_ids).reject(&:blank?))
    organization.labels = labels
    organization
  end

  private

  def self.organization_join_sql(user, join_type: "LEFT OUTER JOIN")
    sanitize_sql_array([
      "#{join_type} conversation_organizations ON conversation_organizations.conversation_id = conversations.id AND conversation_organizations.user_id = ?",
      user.id
    ])
  end
  private_class_method :organization_join_sql
end
