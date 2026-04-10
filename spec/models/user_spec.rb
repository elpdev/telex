require "rails_helper"

RSpec.describe User, type: :model do
  it "normalizes email addresses" do
    user = described_class.create!(email_address: " USER@Example.COM ", password: "password123", password_confirmation: "password123")

    expect(user.email_address).to eq("user@example.com")
  end

  it "rejects invalid email addresses" do
    user = build(:user, email_address: "not-an-email")

    expect(user).not_to be_valid
    expect(user.errors[:email_address]).to include("is invalid")
  end
end
