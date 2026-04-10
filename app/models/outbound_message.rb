class OutboundMessage < ApplicationRecord
  belongs_to :domain
  belongs_to :source_message, class_name: "Message", optional: true

  has_rich_text :body
  has_many_attached :attachments

  enum :status, {
    draft: 0,
    queued: 1,
    sending: 2,
    sent: 3,
    failed: 4
  }

  before_validation :normalize_address_lists

  validate :require_recipients_for_delivery, unless: :draft?
  validate :validate_address_formats, unless: :draft?

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def to_addresses
    super || []
  end

  def cc_addresses
    super || []
  end

  def bcc_addresses
    super || []
  end

  def reference_message_ids
    super || []
  end

  def metadata
    super || {}
  end

  def body_text
    body.to_plain_text
  end

  def references_header_value
    reference_message_ids.join(" ").presence
  end

  def enqueue_delivery!
    self.status = :queued
    self.queued_at = Time.current
    self.failed_at = nil
    self.sent_at = nil
    self.last_error = nil
    save!

    DeliverOutboundMessageJob.perform_later(self)
    self
  end

  def mark_sending!
    update!(status: :sending, last_error: nil)
  end

  def mark_sent!(mail_message_id:)
    update!(status: :sent, sent_at: Time.current, failed_at: nil, last_error: nil, mail_message_id: mail_message_id)
  end

  def mark_failed!(error)
    update!(status: :failed, failed_at: Time.current, last_error: "#{error.class}: #{error.message}")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at delivery_attempts domain_id failed_at id in_reply_to_message_id last_error mail_message_id queued_at sent_at source_message_id status subject updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[attachments_attachments attachments_blobs domain rich_text_body source_message]
  end

  private

  def normalize_address_lists
    self.to_addresses = normalize_addresses(to_addresses)
    self.cc_addresses = normalize_addresses(cc_addresses)
    self.bcc_addresses = normalize_addresses(bcc_addresses)
  end

  def normalize_addresses(values)
    Array(values).filter_map do |value|
      normalized = value.to_s.strip.downcase
      normalized.presence
    end.uniq
  end

  def require_recipients_for_delivery
    errors.add(:to_addresses, "can't be blank") if to_addresses.blank?
  end

  def validate_address_formats
    {to_addresses: to_addresses, cc_addresses: cc_addresses, bcc_addresses: bcc_addresses}.each do |attribute, values|
      next if values.all? { |value| value.match?(URI::MailTo::EMAIL_REGEXP) }

      errors.add(attribute, "contains an invalid email address")
    end
  end
end
