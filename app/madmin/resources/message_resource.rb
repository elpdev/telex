class MessageResource < Madmin::Resource
  attribute :id, form: false
  attribute :inbox
  attribute :inbound_email
  attribute :message_id
  attribute :from_address
  attribute :from_name
  attribute :to_addresses
  attribute :cc_addresses
  attribute :subject
  attribute :subaddress
  attribute :received_at
  attribute :text_body
  attribute :body
  attribute :attachments
  attribute :status
  attribute :processing_error
  attribute :metadata
  attribute :created_at, form: false
  attribute :updated_at, form: false
end
