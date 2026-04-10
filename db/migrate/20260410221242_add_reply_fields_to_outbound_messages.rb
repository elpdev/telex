class AddReplyFieldsToOutboundMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :outbound_messages, :source_message, foreign_key: {to_table: :messages}
    add_column :outbound_messages, :in_reply_to_message_id, :string
    add_column :outbound_messages, :reference_message_ids, :json, null: false, default: []

    add_index :outbound_messages, :in_reply_to_message_id
  end
end
