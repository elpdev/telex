class FolderResource < Madmin::Resource
  attribute :id, form: false
  attribute :user
  attribute :parent
  attribute :children
  attribute :stored_files
  attribute :name
  attribute :source
  attribute :provider
  attribute :provider_identifier
  attribute :metadata
  attribute :created_at, form: false
  attribute :updated_at, form: false
end
