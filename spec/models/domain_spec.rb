require "rails_helper"

RSpec.describe Domain, type: :model do
  it "normalizes and validates the domain name" do
    domain = described_class.create!(name: " LBP.DEV ")

    expect(domain.name).to eq("lbp.dev")
  end

  it "requires a unique name" do
    create(:domain, name: "lbp.dev")
    duplicate = build(:domain, name: "LBP.dev")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to include("has already been taken")
  end
end
