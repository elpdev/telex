FactoryBot.define do
  factory :contact do
    association :user
    contact_type { :person }
    sequence(:name) { |n| "Contact #{n}" }
    metadata { {} }

    trait :business do
      contact_type { :business }
      company_name { name }
    end
  end

  factory :contact_email_address do
    association :contact
    user { contact.user }
    sequence(:email_address) { |n| "contact-#{n}@example.com" }
    label { "email" }
    primary_address { true }
  end

  factory :contact_communication do
    association :contact
    user { contact.user }
    association :communicable, factory: :message
    occurred_at { Time.current }
    metadata { {} }
  end
end
