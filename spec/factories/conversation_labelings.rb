FactoryBot.define do
  factory :conversation_labeling do
    association :conversation_organization
    association :label
  end
end
