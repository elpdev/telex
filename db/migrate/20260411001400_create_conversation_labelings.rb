class CreateConversationLabelings < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_labelings do |t|
      t.references :conversation_organization, null: false, foreign_key: true
      t.references :label, null: false, foreign_key: true

      t.timestamps
    end

    add_index :conversation_labelings, [:conversation_organization_id, :label_id], unique: true
  end
end
