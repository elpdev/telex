class DomainResource < Madmin::Resource
  attribute :id, form: false
  attribute :name
  attribute :active
  attribute :from_name
  attribute :smtp_settings
  attribute :created_at, form: false
  attribute :updated_at, form: false

  attribute :inboxes
end
