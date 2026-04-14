class DomainResource < Madmin::Resource
  attribute :id, form: false
  attribute :user
  attribute :name
  attribute :active
  attribute :outbound_from_name
  attribute :outbound_from_address
  attribute :use_from_address_for_reply_to
  attribute :reply_to_address
  attribute :smtp_host
  attribute :smtp_port
  attribute :smtp_authentication
  attribute :smtp_enable_starttls_auto
  attribute :smtp_username, index: false, show: false
  attribute :smtp_password, index: false, show: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  attribute :inboxes
  attribute :outbound_messages
end
