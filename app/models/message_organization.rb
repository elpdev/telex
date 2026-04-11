class MessageOrganization < ApplicationRecord
  belongs_to :user
  belongs_to :message

  has_many :message_labelings, dependent: :destroy
  has_many :labels, through: :message_labelings

  enum :system_state, {
    inbox: 0,
    archived: 1,
    trash: 2
  }

  validates :message_id, uniqueness: {scope: :user_id}

  def self.for(user, message)
    find_or_create_by!(user: user, message: message)
  end
end
