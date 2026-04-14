class AddUserToDomainsAndInboxes < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  class MigrationDomain < ApplicationRecord
    self.table_name = "domains"
  end

  def up
    add_reference :domains, :user, foreign_key: true

    backfill_domains!

    change_column_null :domains, :user_id, false

    add_index :domains, [:user_id, :name]
  end

  def down
    remove_index :domains, [:user_id, :name]

    remove_reference :domains, :user, foreign_key: true
  end

  private

  def backfill_domains!
    return unless MigrationDomain.where(user_id: nil).exists?

    admin_user = MigrationUser.find_by(admin: true)
    raise ActiveRecord::IrreversibleMigration, "Cannot backfill domains without an admin user" if admin_user.blank?

    MigrationDomain.where(user_id: nil).update_all(user_id: admin_user.id)
  end
end
