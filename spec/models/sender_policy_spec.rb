require "rails_helper"

RSpec.describe SenderPolicy, type: :model do
  it "normalizes values and replaces the disposition for the same target" do
    user = create(:user)

    described_class.set!(user: user, target_kind: :sender, value: " Sender@Example.com ", disposition: :blocked)
    described_class.set!(user: user, target_kind: :sender, value: "sender@example.com", disposition: :trusted)

    expect(user.sender_policies.count).to eq(1)
    expect(user.sender_policies.first.value).to eq("sender@example.com")
    expect(user.sender_policies.first.disposition).to eq("trusted")
  end

  it "matches sender and domain policies against a message" do
    message = create(:message, from_address: "person@example.com")
    sender_policy = build(:sender_policy, value: "person@example.com", target_kind: :sender)
    domain_policy = build(:sender_policy, value: "example.com", target_kind: :domain)

    expect(sender_policy.matches_message?(message)).to eq(true)
    expect(domain_policy.matches_message?(message)).to eq(true)
  end
end
