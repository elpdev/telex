class StoredFileResource < Madmin::Resource
  attribute :id, form: false
  attribute :user
  attribute :folder
  attribute :blob
  attribute :filename
  attribute :mime_type
  attribute :byte_size
  attribute :source
  attribute :provider
  attribute :provider_identifier
  attribute :provider_created_at
  attribute :provider_updated_at
  attribute :image_width
  attribute :image_height
  attribute :metadata
  attribute :created_at, form: false
  attribute :updated_at, form: false
end
