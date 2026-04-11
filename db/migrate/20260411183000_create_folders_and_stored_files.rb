class CreateFoldersAndStoredFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :folders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :parent, foreign_key: {to_table: :folders}
      t.integer :source, null: false, default: 0
      t.string :provider
      t.string :provider_identifier
      t.string :name, null: false
      t.json :metadata

      t.timestamps
    end

    add_index :folders, [:user_id, :parent_id, :name], unique: true
    add_index :folders, [:user_id, :provider, :provider_identifier], unique: true, where: "provider_identifier IS NOT NULL"

    create_table :stored_files do |t|
      t.references :user, null: false, foreign_key: true
      t.references :folder, foreign_key: true
      t.integer :source, null: false, default: 0
      t.string :provider
      t.string :provider_identifier
      t.references :active_storage_blob, foreign_key: {to_table: :active_storage_blobs}
      t.string :filename, null: false
      t.string :mime_type
      t.bigint :byte_size
      t.datetime :provider_created_at
      t.datetime :provider_updated_at
      t.integer :image_width
      t.integer :image_height
      t.json :metadata

      t.timestamps
    end

    add_index :stored_files, [:user_id, :folder_id, :filename]
    add_index :stored_files, [:user_id, :provider, :provider_identifier], unique: true, where: "provider_identifier IS NOT NULL"
  end
end
