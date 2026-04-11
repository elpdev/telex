class CreateCalendarEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_events do |t|
      t.references :calendar, null: false, foreign_key: true
      t.string :uid
      t.string :title, null: false
      t.text :description
      t.string :location
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.boolean :all_day, null: false, default: false
      t.string :time_zone
      t.integer :status, null: false, default: 0
      t.string :organizer_name
      t.string :organizer_email
      t.integer :source, null: false, default: 0
      t.text :raw_payload
      t.text :recurrence_rule
      t.text :recurrence_exceptions
      t.integer :sequence_number, null: false, default: 0
      t.datetime :last_imported_at

      t.timestamps
    end

    add_index :calendar_events, [:calendar_id, :starts_at]
    add_index :calendar_events, [:calendar_id, :uid], unique: true
  end
end
