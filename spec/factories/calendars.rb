FactoryBot.define do
  factory :calendar do
    association :user
    sequence(:name) { |n| "Calendar #{n}" }
    color { "cyan" }
    time_zone { "UTC" }
    source { :local }
    sequence(:position)
  end
end
