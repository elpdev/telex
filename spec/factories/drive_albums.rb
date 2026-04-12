FactoryBot.define do
  factory :drive_album do
    association :user
    sequence(:name) { |n| "Album #{n}" }
  end
end
