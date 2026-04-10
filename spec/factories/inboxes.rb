FactoryBot.define do
  factory :inbox do
    association :domain
    sequence(:local_part) { |n| "inbox#{n}" }
    pipeline_key { "default" }
    active { true }
    description { "Test inbox" }
    pipeline_overrides { {} }
    forwarding_rules { [] }
  end
end
