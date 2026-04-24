class AddInboxToOutboundMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :outbound_messages, :inbox, foreign_key: true
  end
end
