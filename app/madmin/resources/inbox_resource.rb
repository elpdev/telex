class InboxResource < Madmin::Resource
  attribute :id, form: false
  attribute :domain
  attribute :local_part
  attribute :address
  attribute :pipeline_key
  attribute :pipeline_overrides
  attribute :description
  attribute :active
  attribute :created_at, form: false
  attribute :updated_at, form: false

  attribute :messages
end
