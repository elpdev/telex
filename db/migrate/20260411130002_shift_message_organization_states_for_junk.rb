class ShiftMessageOrganizationStatesForJunk < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE message_organizations
      SET system_state = CASE system_state
      WHEN 2 THEN 3
      WHEN 1 THEN 2
      ELSE system_state
      END
    SQL
  end

  def down
    execute <<~SQL
      UPDATE message_organizations
      SET system_state = CASE system_state
      WHEN 3 THEN 2
      WHEN 2 THEN 1
      ELSE system_state
      END
    SQL
  end
end
