class Message < ApplicationRecord
  belongs_to :inbox
  belongs_to :inbound_email, class_name: "ActionMailbox::InboundEmail"

  has_rich_text :body
  has_many_attached :attachments

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

  def preview_text
    text_body.to_s.squish.presence || body.to_plain_text.squish.presence || "No preview available"
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at from_address from_name id inbox_id message_id received_at status subject subaddress text_body updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[inbox rich_text_body]
  end
end
