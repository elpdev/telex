class AddUserIdToDomains < ActiveRecord::Migration[8.1]
  def change
    add_column :domains, :user_id, :integer
    add_index :domains, :user_id
    add_foreign_key :domains, :users
  end
end
