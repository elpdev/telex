FactoryBot.define do
  factory :label do
    association :user
    sequence(:name) { |n| "Label #{n}" }
    color { nil }
  end
end
