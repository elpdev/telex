class CreateCalendarEventLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_event_links do |t|
      t.references :calendar_event, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true
      t.string :ical_uid
      t.string :ical_method
      t.integer :sequence_number, null: false, default: 0

      t.timestamps
    end

    add_index :calendar_event_links, [:calendar_event_id, :message_id], unique: true
    add_index :calendar_event_links, :ical_uid
  end
end
