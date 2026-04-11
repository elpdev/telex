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

  it "normalizes and matches forwarding rules" do
    inbox = build(:inbox, forwarding_rules: [{
      "name" => " Receipts ",
      "active" => true,
      "from_address_pattern" => " AMAZON ",
      "subject_pattern" => " receipt ",
      "subaddress_pattern" => " orders ",
      "target_addresses" => [" OPS@EXAMPLE.COM ", "ops@example.com"]
    }])
    message = build(:message, inbox: inbox, from_address: "shipping@amazon.com", subject: "Your receipt", subaddress: "orders")

    expect(inbox).to be_valid
    expect(inbox.active_forwarding_rules.first).to eq(
      {
        "name" => "Receipts",
        "active" => true,
        "from_address_pattern" => "amazon",
        "subject_pattern" => "receipt",
        "subaddress_pattern" => "orders",
        "target_addresses" => ["ops@example.com"]
      }
    )
    expect(inbox.matching_forwarding_rules(message).size).to eq(1)
  end

  it "requires forwarding rules to include target addresses" do
    inbox = build(:inbox, forwarding_rules: [{"name" => "Missing targets", "target_addresses" => []}])

    expect(inbox).not_to be_valid
    expect(inbox.errors[:forwarding_rules]).to include("rule 1 must include at least one target address")
  end

  it "accepts forwarding rules submitted as JSON text" do
    inbox = build(:inbox, forwarding_rules: <<~JSON)
      [
        {
          "name": " Ops ",
          "target_addresses": [" OPS@example.com "],
          "active": true
        }
      ]
    JSON

    expect(inbox).to be_valid
    expect(inbox.forwarding_rules).to eq([
      {
        "name" => " Ops ",
        "target_addresses" => [" OPS@example.com "],
        "active" => true
      }
    ])
    expect(inbox.active_forwarding_rules.first["target_addresses"]).to eq(["ops@example.com"])
  end

  it "treats blank forwarding rules text as an empty array" do
    inbox = build(:inbox, forwarding_rules: "   ")

    expect(inbox).to be_valid
    expect(inbox.forwarding_rules).to eq([])
  end

  it "rejects invalid forwarding rules JSON text" do
    inbox = build(:inbox, forwarding_rules: '{"name" => "bad"}')

    expect(inbox).not_to be_valid
    expect(inbox.errors[:forwarding_rules]).to include("must be valid JSON")
  end

  it "rejects forwarding rules JSON that is not an array" do
    inbox = build(:inbox, forwarding_rules: '{"name":"bad"}')

    expect(inbox).not_to be_valid
    expect(inbox.errors[:forwarding_rules]).to include("must be a JSON array")
  end

  it "accepts pipeline overrides submitted as JSON text" do
    inbox = build(:inbox, pipeline_overrides: '{"notify_user_id":1}')

    expect(inbox).to be_valid
    expect(inbox.pipeline_overrides).to eq({"notify_user_id" => 1})
  end

  it "rejects invalid pipeline overrides JSON text" do
    inbox = build(:inbox, pipeline_overrides: '{"notify_user_id" => 1}')

    expect(inbox).not_to be_valid
    expect(inbox.errors[:pipeline_overrides]).to include("must be valid JSON")
  end

  it "rejects pipeline overrides JSON that is not an object" do
    inbox = build(:inbox, pipeline_overrides: "[]")

    expect(inbox).not_to be_valid
    expect(inbox.errors[:pipeline_overrides]).to include("must be a JSON object")
  end
end
