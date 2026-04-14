class AddDriveFolderToDomainsAndInboxes < ActiveRecord::Migration[8.1]
  def change
    add_reference :domains, :drive_folder, foreign_key: {to_table: :folders}
    add_reference :inboxes, :drive_folder, foreign_key: {to_table: :folders}
  end
end
