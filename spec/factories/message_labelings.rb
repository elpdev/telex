FactoryBot.define do
  factory :message_labeling do
    association :message_organization
    association :label
  end
end
