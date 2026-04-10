FactoryBot.define do
  factory :message do
    association :inbox
    association :inbound_email, factory: :action_mailbox_inbound_email
    sequence(:message_id) { |n| "message-#{n}@example.com" }
    from_address { "sender@example.com" }
    from_name { "Sender" }
    to_addresses { [inbox.address] }
    cc_addresses { [] }
    subject { "Hello" }
    received_at { Time.current }
    text_body { "Plain text body" }
    status { :received }
    metadata { {} }
  end

  factory :action_mailbox_inbound_email, class: "ActionMailbox::InboundEmail" do
    transient do
      source do
        <<~EMAIL
          From: Sender <sender@example.com>
          To: inbox@example.com
          Subject: Test message
          Message-ID: <factory-#{SecureRandom.hex(8)}@example.com>
          Date: Fri, 10 Apr 2026 10:00:00 +0000
          MIME-Version: 1.0
          Content-Type: text/plain; charset=UTF-8

          Hello from the factory.
        EMAIL
      end
    end

    initialize_with do
      ActionMailbox::InboundEmail.create_and_extract_message_id!(source)
    end
  end
end
