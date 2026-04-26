class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :note_file, foreign_key: {to_table: :stored_files}
      t.integer :contact_type, null: false, default: 0
      t.string :name
      t.string :company_name
      t.string :title
      t.string :phone
      t.string :website
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :contacts, [:user_id, :contact_type]
    add_index :contacts, [:user_id, :name]

    create_table :contact_email_addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :email_address, null: false
      t.string :label
      t.boolean :primary_address, null: false, default: false

      t.timestamps
    end

    add_index :contact_email_addresses, [:user_id, :email_address], unique: true
    add_index :contact_email_addresses, [:contact_id, :primary_address]

    create_table :contact_communications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :communicable, polymorphic: true, null: false
      t.datetime :occurred_at, null: false
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :contact_communications, [:contact_id, :occurred_at]
    add_index :contact_communications, [:user_id, :communicable_type, :communicable_id], name: "index_contact_comms_on_user_and_communicable"
    add_index :contact_communications, [:contact_id, :communicable_type, :communicable_id], unique: true, name: "index_contact_comms_uniqueness"

    add_reference :messages, :contact, foreign_key: true
  end
end
