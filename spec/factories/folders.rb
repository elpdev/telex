FactoryBot.define do
  factory :folder do
    association :user
    sequence(:name) { |n| "Folder #{n}" }
    source { :local }
    metadata { {} }
  end
end
