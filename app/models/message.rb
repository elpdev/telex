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
end
