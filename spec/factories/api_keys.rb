FactoryBot.define do
  factory :api_key do
    association :user
    sequence(:name) { |n| "Key #{n}" }
    client_id { nil }
    expires_at { nil }
    secret_key { "test_secret_key_12345" }
    secret_key_confirmation { secret_key }
  end
end
