class Message < ApplicationRecord
  belongs_to :inbox
  belongs_to :inbound_email, class_name: "ActionMailbox::InboundEmail"
  belongs_to :conversation, optional: true

  has_rich_text :body
  has_many_attached :attachments

  after_create :assign_conversation

  enum :status, {
    received: 0,
    processing: 1,
    processed: 2,
    failed: 3
  }

  validates :received_at, presence: true
  validates :inbound_email_id, uniqueness: {scope: :inbox_id}

  scope :newest_first, -> { order(received_at: :desc, id: :desc) }

  def metadata
    super || {}
  end

  def to_addresses
    super || []
  end

  def cc_addresses
    super || []
  end

  def sender_display
    from_name.presence || from_address.presence || "Unknown sender"
  end

  def in_reply_to_message_id
    normalize_message_id(inbound_email.mail.header["In-Reply-To"]&.value)
  end

  def reference_message_ids
    inbound_email.mail.header["References"]&.value.to_s.scan(/<[^>]+>/).uniq
  end

  def participant_addresses
    ([from_address] + to_addresses + cc_addresses).filter_map do |value|
      value.to_s.strip.downcase.presence
    end.uniq.sort
  end

  def subject_key
    Conversations::SubjectNormalizer.normalize(subject)
  end

  def occurred_at
    received_at || created_at
  end

  def normalized_message_id
    normalize_message_id(message_id)
  end

  def preview_text
    text_body.to_s.squish.presence || body.to_plain_text.squish.presence || "No preview available"
  end

  def raw_html_body
    return @raw_html_body if defined?(@raw_html_body)

    @raw_html_body = if inbound_email.mail.multipart?
      inbound_email.mail.html_part&.decoded.presence
    elsif inbound_email.mail.mime_type.to_s.include?("html")
      inbound_email.mail.body.decoded.presence
    end
  end

  def html_email?
    raw_html_body.present?
  end

  def inline_asset_token(content_id)
    Base64.urlsafe_encode64(normalize_content_id(content_id), padding: false)
  end

  def inline_part_for_token(token)
    content_id = Base64.urlsafe_decode64(token.to_s)
    inline_part_for_content_id(content_id)
  rescue ArgumentError
    nil
  end

  def inline_part_for_content_id(content_id)
    normalized = normalize_content_id(content_id)

    inbound_email.mail.all_parts.find do |part|
      part.content_id.present? && normalize_content_id(part.content_id) == normalized
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at from_address from_name id inbox_id message_id received_at status subject subaddress text_body updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[conversation inbox rich_text_body]
  end

  private

  def normalize_content_id(content_id)
    content_id.to_s.strip.delete_prefix("<").delete_suffix(">")
  end

  def normalize_message_id(value)
    stripped = value.to_s.strip
    return if stripped.blank?

    return stripped if stripped.start_with?("<") && stripped.end_with?(">")

    "<#{stripped}>"
  end

  def assign_conversation
    return if conversation_id.present?

    Conversations::Resolver.assign!(self)
  end
end
