class CreateDomainsInboxesMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :domains do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.json :smtp_settings
      t.string :from_name

      t.timestamps
    end

    add_index :domains, :name, unique: true

    create_table :inboxes do |t|
      t.references :domain, null: false, foreign_key: true
      t.string :local_part, null: false
      t.string :address, null: false
      t.string :pipeline_key, null: false, default: "default"
      t.json :pipeline_overrides
      t.string :description
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :inboxes, :address, unique: true
    add_index :inboxes, :active
    add_index :inboxes, [:domain_id, :local_part], unique: true

    create_table :messages do |t|
      t.references :inbox, null: false, foreign_key: true
      t.references :inbound_email, null: false, foreign_key: {to_table: :action_mailbox_inbound_emails}
      t.string :message_id
      t.string :from_address
      t.string :from_name
      t.json :to_addresses
      t.json :cc_addresses
      t.string :subject
      t.string :subaddress
      t.datetime :received_at, null: false
      t.text :text_body
      t.integer :status, null: false, default: 0
      t.text :processing_error
      t.json :metadata

      t.timestamps
    end

    add_index :messages, :message_id
    add_index :messages, :received_at
    add_index :messages, :subaddress
    add_index :messages, [:inbox_id, :inbound_email_id], unique: true
  end
end
