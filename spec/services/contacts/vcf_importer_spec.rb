require "rails_helper"

RSpec.describe Contacts::VcfImporter do
  it "imports iPhone vCards including phone-only contacts and metadata" do
    user = create(:user)

    result = described_class.call(
      user: user,
      file: fixture_file_upload("contacts/iphone_export.vcf", "text/vcard")
    )

    expect(result).to be_success
    expect(result.created).to eq(3)
    expect(result.updated).to eq(0)
    expect(user.contacts.count).to eq(3)

    jane = user.contacts.find_by!(name: "Jane Doe")
    expect(jane.phone).to eq("(555) 123-4567")
    expect(jane.company_name).to eq("Acme Inc.")
    expect(jane.title).to eq("Lead Engineer")
    expect(jane.metadata.dig("vcard", "phones")).to include("+1 555 999 0000")
    expect(jane.metadata.dig("vcard", "note")).to eq("Met at WWDC\nPrefers texts")
    expect(jane.metadata.dig("vcard", "bday")).to eq("1985-04-12")

    alice = user.contacts.find_by!(name: "Alice Smith")
    expect(alice.primary_email_address.email_address).to eq("alice@example.com")
    expect(alice.email_addresses.pluck(:email_address)).to contain_exactly("alice@example.com", "alice.work@example.com")
    expect(alice.website).to eq("https://example.com/alice")
    expect(alice.metadata.dig("vcard", "x-socialprofile")).to eq("x-apple:alice")

    folded = user.contacts.find_by!(name: "Folded Note")
    expect(folded.metadata.dig("vcard", "note")).to eq("This is a long note that continueson the next line")
  end

  it "updates existing contacts by email or normalized phone" do
    user = create(:user)
    phone_contact = create(:contact, user: user, name: "Old Jane", phone: "+1 555 123 4567", metadata: {"source" => "manual"})
    email_contact = create(:contact, user: user, name: "Old Alice")
    email_contact.email_addresses.create!(user: user, email_address: "alice@example.com", primary_address: true)

    result = described_class.call(
      user: user,
      file: fixture_file_upload("contacts/iphone_export.vcf", "text/vcard")
    )

    expect(result).to be_success
    expect(result.created).to eq(1)
    expect(result.updated).to eq(2)
    expect(user.contacts.count).to eq(3)

    expect(phone_contact.reload.name).to eq("Jane Doe")
    expect(phone_contact.metadata["source"]).to eq("manual")
    expect(email_contact.reload.name).to eq("Alice Smith")
    expect(email_contact.email_addresses.pluck(:email_address)).to include("alice.work@example.com")
  end
end
