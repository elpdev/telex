require "rails_helper"

RSpec.describe EmailSignature, type: :model do
  describe "validations" do
    it "requires a name" do
      signature = build(:email_signature, name: nil)
      expect(signature).not_to be_valid
      expect(signature.errors[:name]).to include("can't be blank")
    end
  end

  describe "default signature swapping" do
    it "promoting a new signature to default demotes any existing default" do
      domain = create(:domain)
      original = create(:email_signature, domain: domain, is_default: true)
      replacement = create(:email_signature, domain: domain, is_default: true)

      expect(original.reload).not_to be_is_default
      expect(replacement.reload).to be_is_default
    end

    it "only demotes defaults on the same domain" do
      other_domain = create(:domain)
      other_default = create(:email_signature, domain: other_domain, is_default: true)

      domain = create(:domain)
      create(:email_signature, domain: domain, is_default: true)

      expect(other_default.reload).to be_is_default
    end

    it "does not demote a non-default signature" do
      domain = create(:domain)
      create(:email_signature, domain: domain, is_default: true)

      non_default = create(:email_signature, domain: domain, is_default: false)

      expect(non_default.reload).not_to be_is_default
    end
  end

  describe ".default_for" do
    it "returns the default signature scoped to the domain" do
      domain = create(:domain)
      default = create(:email_signature, domain: domain, is_default: true)
      create(:email_signature, domain: domain, is_default: false)

      expect(EmailSignature.default_for(domain)).to eq([default])
    end
  end
end
