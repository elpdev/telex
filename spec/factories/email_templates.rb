FactoryBot.define do
  factory :email_template do
    association :domain
    sequence(:name) { |n| "Template #{n}" }
    subject { "Re: your request" }
    body { "<div>Thanks for reaching out.</div>" }
  end
end
