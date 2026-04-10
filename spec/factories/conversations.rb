FactoryBot.define do
  factory :conversation do
    sequence(:subject_key) { |n| "subject-#{n}" }
    participant_addresses { ["sender@example.com", "inbox@example.com"] }
    last_message_at { Time.current }
  end
end
