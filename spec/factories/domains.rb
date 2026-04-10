FactoryBot.define do
  factory :domain do
    sequence(:name) { |n| "domain#{n}.test" }
    active { true }

    trait :with_outbound_configuration do
      outbound_from_name { "InboxOS" }
      outbound_from_address { "hello@#{name}" }
      use_from_address_for_reply_to { true }
      smtp_host { "smtp.#{name}" }
      smtp_port { 587 }
      smtp_username { "smtp-user" }
      smtp_password { "smtp-pass" }
      smtp_authentication { "login" }
      smtp_enable_starttls_auto { true }
    end
  end
end
