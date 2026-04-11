FactoryBot.define do
  factory :email_signature do
    association :domain
    sequence(:name) { |n| "Signature #{n}" }
    is_default { false }
    body { "<div>-- <br>Support Team</div>" }
  end
end
