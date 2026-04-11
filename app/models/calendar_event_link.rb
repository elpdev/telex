class CalendarEventLink < ApplicationRecord
  belongs_to :calendar_event
  belongs_to :message

  validates :message_id, uniqueness: {scope: :calendar_event_id}
end
