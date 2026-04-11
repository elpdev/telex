class CreateConversationOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_organizations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.integer :system_state, null: false, default: 0

      t.timestamps
    end

    add_index :conversation_organizations, [:user_id, :conversation_id], unique: true
    add_index :conversation_organizations, [:user_id, :system_state]
  end
end
