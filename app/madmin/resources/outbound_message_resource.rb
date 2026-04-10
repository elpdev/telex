class OutboundMessageResource < Madmin::Resource
  attribute :id, form: false
  attribute :domain
  attribute :to_addresses
  attribute :cc_addresses
  attribute :bcc_addresses
  attribute :subject
  attribute :body
  attribute :attachments
  attribute :status
  attribute :delivery_attempts
  attribute :mail_message_id
  attribute :last_error
  attribute :queued_at
  attribute :sent_at
  attribute :failed_at
  attribute :metadata
  attribute :created_at, form: false
  attribute :updated_at, form: false
end
