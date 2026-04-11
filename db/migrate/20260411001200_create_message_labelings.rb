class CreateMessageLabelings < ActiveRecord::Migration[8.1]
  def change
    create_table :message_labelings do |t|
      t.references :message_organization, null: false, foreign_key: true
      t.references :label, null: false, foreign_key: true

      t.timestamps
    end

    add_index :message_labelings, [:message_organization_id, :label_id], unique: true
  end
end
