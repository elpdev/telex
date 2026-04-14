class RemoveLegacyInboxUserIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :inboxes, name: "index_inboxes_on_user_id_and_address", if_exists: true
  end
end
