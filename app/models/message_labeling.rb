class MessageLabeling < ApplicationRecord
  belongs_to :message_organization
  belongs_to :label

  validates :label_id, uniqueness: {scope: :message_organization_id}
end
