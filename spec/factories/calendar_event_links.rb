FactoryBot.define do
  factory :calendar_event_link do
    association :calendar_event
    association :message
    ical_uid { "invite-link-1" }
    ical_method { "REQUEST" }
    sequence(:sequence_number)
  end
end
