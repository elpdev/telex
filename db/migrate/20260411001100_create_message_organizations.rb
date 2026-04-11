class CreateMessageOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :message_organizations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true
      t.integer :system_state, null: false, default: 0

      t.timestamps
    end

    add_index :message_organizations, [:user_id, :message_id], unique: true
    add_index :message_organizations, [:user_id, :system_state]
  end
end
