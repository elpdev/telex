class CreateDriveAlbums < ActiveRecord::Migration[8.0]
  def change
    create_table :drive_albums do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :drive_albums, [:user_id, :name], unique: true

    create_table :drive_album_memberships do |t|
      t.references :drive_album, null: false, foreign_key: true
      t.references :stored_file, null: false, foreign_key: true

      t.timestamps
    end

    add_index :drive_album_memberships, [:drive_album_id, :stored_file_id], unique: true, name: "index_drive_album_memberships_on_album_and_file"
  end
end
