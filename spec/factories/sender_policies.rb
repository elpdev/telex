FactoryBot.define do
  factory :sender_policy do
    association :user
    target_kind { :sender }
    disposition { :blocked }
    value { "sender@example.com" }
  end
end
