FactoryBot.define do
  factory :conversation_organization do
    association :user
    association :conversation
    system_state { :inbox }
  end
end
