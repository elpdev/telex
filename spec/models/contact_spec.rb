require "rails_helper"

RSpec.describe Contact, type: :model do
  it "finds or creates a person contact for an email address" do
    user = create(:user)

    contact = described_class.find_or_create_for_email!(user: user, email_address: " Sender@Example.com ", name: "Sender")

    expect(contact).to be_person
    expect(contact.name).to eq("Sender")
    expect(contact.email_addresses.first.email_address).to eq("sender@example.com")
    expect(described_class.find_or_create_for_email!(user: user, email_address: "sender@example.com")).to eq(contact)
  end
end
