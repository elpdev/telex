class AddIncrementalSyncIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :calendars, [:user_id, :updated_at], if_not_exists: true
    add_index :contacts, [:user_id, :updated_at], if_not_exists: true
    add_index :contact_email_addresses, [:contact_id, :updated_at], if_not_exists: true
    add_index :folders, [:user_id, :updated_at], if_not_exists: true
    add_index :message_organizations, [:user_id, :message_id, :updated_at], if_not_exists: true
    add_index :messages, :updated_at, if_not_exists: true
    add_index :outbound_messages, [:user_id, :updated_at], if_not_exists: true
    add_index :stored_files, [:user_id, :updated_at], if_not_exists: true
    add_index :calendar_events, [:calendar_id, :updated_at], if_not_exists: true
  end
end
