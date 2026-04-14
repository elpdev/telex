class RemoveUserFromInboxes < ActiveRecord::Migration[8.1]
  def change
    remove_reference :inboxes, :user, foreign_key: true, index: true
  end
end
