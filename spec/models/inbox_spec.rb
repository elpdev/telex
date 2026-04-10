require "rails_helper"

RSpec.describe Inbox, type: :model do
  it "builds the normalized address from local part and domain" do
    inbox = create(:inbox, domain: create(:domain, name: "LBP.dev"), local_part: "Receipts")

    expect(inbox.address).to eq("receipts@lbp.dev")
  end

  it "requires a registered pipeline" do
    inbox = build(:inbox, pipeline_key: "missing")

    expect(inbox).not_to be_valid
    expect(inbox.errors[:pipeline_key]).to include("is not registered")
  end

  it "enforces uniqueness within a domain" do
    domain = create(:domain)
    create(:inbox, domain: domain, local_part: "home")
    duplicate = build(:inbox, domain: domain, local_part: "HOME")

    expect(duplicate).not_to be_valid
  end
end
