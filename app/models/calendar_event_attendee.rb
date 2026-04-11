class CalendarEventAttendee < ApplicationRecord
  belongs_to :calendar_event

  enum :role, {
    required: 0,
    optional: 1,
    chair: 2,
    non_participant: 3
  }

  enum :participation_status, {
    needs_action: 0,
    accepted: 1,
    tentative: 2,
    declined: 3
  }

  normalizes :email, with: ->(value) { value.to_s.strip.downcase }
  normalizes :name, with: ->(value) { value.to_s.strip.presence }

  validates :email, presence: true, uniqueness: {scope: :calendar_event_id}
end
