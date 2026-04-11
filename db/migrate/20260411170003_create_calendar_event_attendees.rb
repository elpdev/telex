class CreateCalendarEventAttendees < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_event_attendees do |t|
      t.references :calendar_event, null: false, foreign_key: true
      t.string :email, null: false
      t.string :name
      t.integer :role, null: false, default: 0
      t.integer :participation_status, null: false, default: 0
      t.boolean :response_requested, null: false, default: false

      t.timestamps
    end

    add_index :calendar_event_attendees, [:calendar_event_id, :email], unique: true
  end
end
