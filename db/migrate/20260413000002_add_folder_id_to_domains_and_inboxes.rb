class AddFolderIdToDomainsAndInboxes < ActiveRecord::Migration[8.1]
  def change
    add_column :domains, :folder_id, :integer
    add_index :domains, :folder_id
    add_foreign_key :domains, :folders

    add_column :inboxes, :folder_id, :integer
    add_index :inboxes, :folder_id
    add_foreign_key :inboxes, :folders
  end
end
