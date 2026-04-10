class AddForwardingRulesToInboxes < ActiveRecord::Migration[8.1]
  def change
    add_column :inboxes, :forwarding_rules, :json, null: false, default: []
  end
end
