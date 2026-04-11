FactoryBot.define do
  factory :outbound_message do
    association :domain, :with_outbound_configuration
    association :user
    association :source_message, factory: :message
    to_addresses { ["recipient@example.com"] }
    cc_addresses { [] }
    bcc_addresses { [] }
    subject { "Outbound subject" }
    status { :draft }
    metadata { {} }

    after(:build) do |outbound_message|
      outbound_message.body = "<div><strong>Hello</strong> from outbound mail.</div>" if outbound_message.body.blank?
    end
  end
end
