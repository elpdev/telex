class CreateOutboundMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :outbound_messages do |t|
      t.references :domain, null: false, foreign_key: true
      t.json :to_addresses, null: false, default: []
      t.json :cc_addresses, null: false, default: []
      t.json :bcc_addresses, null: false, default: []
      t.string :subject
      t.integer :status, null: false, default: 0
      t.integer :delivery_attempts, null: false, default: 0
      t.string :mail_message_id
      t.text :last_error
      t.datetime :queued_at
      t.datetime :sent_at
      t.datetime :failed_at
      t.json :metadata
      t.timestamps
    end

    add_index :outbound_messages, :status
    add_index :outbound_messages, :queued_at
    add_index :outbound_messages, :sent_at
    add_index :outbound_messages, :mail_message_id
  end
end
