class AddUserToOutboundMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :outbound_messages, :user, foreign_key: true
    add_index :outbound_messages, [:user_id, :status, :updated_at]
  end
end
