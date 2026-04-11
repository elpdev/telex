class ConversationLabeling < ApplicationRecord
  belongs_to :conversation_organization
  belongs_to :label

  validates :label_id, uniqueness: {scope: :conversation_organization_id}
end
