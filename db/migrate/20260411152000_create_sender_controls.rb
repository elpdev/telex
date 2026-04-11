class CreateSenderControls < ActiveRecord::Migration[8.1]
  def change
    create_table :sender_controls, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :kind, null: false
      t.integer :disposition, null: false
      t.string :value, null: false

      t.timestamps
    end

    add_index :sender_controls, :user_id, if_not_exists: true
    add_index :sender_controls, [:user_id, :disposition], if_not_exists: true
    add_index :sender_controls, [:user_id, :kind, :value], unique: true, if_not_exists: true, name: "index_sender_controls_on_user_id_and_kind_and_value"
  end
end
