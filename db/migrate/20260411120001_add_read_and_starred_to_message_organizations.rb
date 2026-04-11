class AddReadAndStarredToMessageOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :message_organizations, :read_at, :datetime
    add_column :message_organizations, :starred, :boolean, default: false, null: false
    add_index :message_organizations, [:user_id, :starred]
  end
end
