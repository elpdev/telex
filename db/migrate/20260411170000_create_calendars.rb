class CreateCalendars < ActiveRecord::Migration[8.1]
  def change
    create_table :calendars do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: "cyan"
      t.string :time_zone, null: false, default: "UTC"
      t.integer :source, null: false, default: 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :calendars, [:user_id, :position]
    add_index :calendars, [:user_id, :name]
  end
end
