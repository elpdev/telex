require "rails_helper"

RSpec.describe Outbound::SignatureInjector do
  describe ".call" do
    it "returns the existing body unchanged when the domain has no default signature" do
      domain = create(:domain)

      result = described_class.call(domain: domain, existing: "<p>forwarded body</p>")

      expect(result).to eq("<p>forwarded body</p>")
    end

    it "returns an empty string when there is no signature and no existing body" do
      domain = create(:domain)

      expect(described_class.call(domain: domain)).to eq("")
    end

    it "prepends the default signature (with spacer) when one exists" do
      domain = create(:domain)
      create(:email_signature, domain: domain, is_default: true, body: "<div>Signed, Ops</div>")

      result = described_class.call(domain: domain)

      expect(result).to include("Signed, Ops")
      expect(result).to start_with("<div><br></div><div><br></div>")
    end

    it "keeps the existing body below the signature" do
      domain = create(:domain)
      create(:email_signature, domain: domain, is_default: true, body: "<div>Signed, Ops</div>")

      result = described_class.call(domain: domain, existing: "<div>---------- Forwarded message ----------</div>")

      sig_index = result.index("Signed, Ops")
      forward_index = result.index("Forwarded message")
      expect(sig_index).to be < forward_index
    end

    it "ignores non-default signatures" do
      domain = create(:domain)
      create(:email_signature, domain: domain, is_default: false, body: "<div>Other sig</div>")

      expect(described_class.call(domain: domain)).to eq("")
    end

    it "scopes the default signature to the given domain" do
      domain = create(:domain)
      other_domain = create(:domain)
      create(:email_signature, domain: other_domain, is_default: true, body: "<div>Other sig</div>")

      expect(described_class.call(domain: domain)).to eq("")
    end
  end
end
