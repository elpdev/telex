FactoryBot.define do
  factory :calendar_event do
    association :calendar
    sequence(:title) { |n| "Event #{n}" }
    starts_at { Time.zone.parse("2026-04-15 10:00:00") }
    ends_at { Time.zone.parse("2026-04-15 11:00:00") }
    all_day { false }
    time_zone { "UTC" }
    status { :confirmed }
    source { :manual }
    recurrence_exceptions { [] }

    trait :weekly do
      recurrence_rule { "FREQ=WEEKLY;INTERVAL=1;BYDAY=WE;COUNT=4" }
    end
  end
end
