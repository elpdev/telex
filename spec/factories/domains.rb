FactoryBot.define do
  factory :domain do
    sequence(:name) { |n| "domain#{n}.test" }
    active { true }
  end
end
