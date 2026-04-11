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

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current)
  end

  def mark_unread!
    update!(read_at: nil)
  end

  def star!
    update!(starred: true)
  end

  def unstar!
    update!(starred: false)
  end
end
