class ConversationOrganization < ApplicationRecord
  belongs_to :user
  belongs_to :conversation

  has_many :conversation_labelings, dependent: :destroy
  has_many :labels, through: :conversation_labelings

  enum :system_state, {
    inbox: 0,
    archived: 1,
    trash: 2
  }

  validates :conversation_id, uniqueness: {scope: :user_id}

  def self.for(user, conversation)
    find_or_create_by!(user: user, conversation: conversation)
  end
end
