class ReplaceDomainOutboundSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :domains, :smtp_settings, :json
    remove_column :domains, :from_name, :string

    add_column :domains, :outbound_from_name, :string
    add_column :domains, :outbound_from_address, :string
    add_column :domains, :reply_to_address, :string
    add_column :domains, :use_from_address_for_reply_to, :boolean, default: true, null: false
    add_column :domains, :smtp_host, :string
    add_column :domains, :smtp_port, :integer
    add_column :domains, :smtp_username, :text
    add_column :domains, :smtp_password, :text
    add_column :domains, :smtp_authentication, :string
    add_column :domains, :smtp_enable_starttls_auto, :boolean, default: true, null: false
  end
end
