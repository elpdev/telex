FactoryBot.define do
  factory :message_organization do
    association :user
    association :message
    system_state { :inbox }
  end
end
