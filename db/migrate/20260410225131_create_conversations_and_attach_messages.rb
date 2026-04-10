class CreateConversationsAndAttachMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :subject_key, null: false
      t.json :participant_addresses, null: false, default: []
      t.datetime :last_message_at, null: false

      t.timestamps
    end

    add_index :conversations, :subject_key
    add_index :conversations, :last_message_at

    add_reference :messages, :conversation, foreign_key: true
    add_reference :outbound_messages, :conversation, foreign_key: true
  end
end
