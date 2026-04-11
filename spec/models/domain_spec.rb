require "rails_helper"

RSpec.describe Domain, type: :model do
  it "normalizes and validates the domain name" do
    domain = described_class.create!(name: " LBP.DEV ")

    expect(domain.name).to eq("lbp.dev")
  end

  it "normalizes outbound email fields" do
    domain = create(
      :domain,
      :with_outbound_configuration,
      outbound_from_name: "  Inbox Team  ",
      outbound_from_address: " SUPPORT@LBP.DEV ",
      reply_to_address: " REPLIES@LBP.DEV ",
      use_from_address_for_reply_to: false,
      smtp_host: " SMTP.LBP.DEV ",
      smtp_authentication: " LOGIN "
    )

    expect(domain.outbound_from_name).to eq("Inbox Team")
    expect(domain.outbound_from_address).to eq("support@lbp.dev")
    expect(domain.reply_to_address).to eq("replies@lbp.dev")
    expect(domain.smtp_host).to eq("smtp.lbp.dev")
    expect(domain.smtp_authentication).to eq("login")
  end

  it "requires a unique name" do
    create(:domain, name: "lbp.dev")
    duplicate = build(:domain, name: "LBP.dev")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to include("has already been taken")
  end

  it "allows domains with no outbound configuration yet" do
    domain = build(:domain)

    expect(domain).to be_valid
    expect(domain.outbound_ready?).to be(false)
  end

  it "requires a complete outbound configuration once setup starts" do
    domain = build(:domain, outbound_from_address: "hello@lbp.dev")

    expect(domain).not_to be_valid
    expect(domain.errors[:outbound_from_name]).to include("can't be blank")
    expect(domain.errors[:smtp_host]).to include("can't be blank")
    expect(domain.errors[:smtp_port]).to include("can't be blank")
    expect(domain.errors[:smtp_username]).to include("can't be blank")
    expect(domain.errors[:smtp_password]).to include("can't be blank")
    expect(domain.errors[:smtp_authentication]).to include("can't be blank")
  end

  it "requires reply_to_address when reply-to should differ" do
    domain = build(:domain, :with_outbound_configuration, use_from_address_for_reply_to: false, reply_to_address: nil)

    expect(domain).not_to be_valid
    expect(domain.errors[:reply_to_address]).to include("can't be blank")
  end

  it "exposes a resolved outbound identity for ready domains" do
    domain = create(:domain, :with_outbound_configuration)

    expect(domain.outbound_ready?).to be(true)
    expect(domain.outbound_identity).to eq(
      {
        from: "Telex <hello@#{domain.name}>",
        from_name: "Telex",
        from_address: "hello@#{domain.name}",
        reply_to: "hello@#{domain.name}"
      }
    )
  end

  it "returns smtp delivery settings for ready domains" do
    domain = create(:domain, :with_outbound_configuration)

    expect(domain.smtp_delivery_settings).to eq(
      {
        address: "smtp.#{domain.name}",
        port: 587,
        user_name: "smtp-user",
        password: "smtp-pass",
        authentication: :login,
        enable_starttls_auto: true
      }
    )
  end

  it "does not consider inactive domains outbound ready" do
    domain = create(:domain, :with_outbound_configuration, active: false)

    expect(domain.outbound_ready?).to be(false)
    expect(domain.outbound_configuration_errors).to include("domain must be active")
  end
end
