require "rails_helper"

RSpec.describe Outbound::DomainConfiguration do
  describe ".resolve!" do
    it "returns the sender identity and smtp settings for a ready domain" do
      domain = create(:domain, :with_outbound_configuration)

      configuration = described_class.resolve!(domain)

      expect(configuration.from).to eq("InboxOS <hello@#{domain.name}>")
      expect(configuration.reply_to).to eq("hello@#{domain.name}")
      expect(configuration.smtp_settings).to eq(
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

    it "uses a custom reply-to address when configured" do
      domain = create(
        :domain,
        :with_outbound_configuration,
        name: "replies.test",
        use_from_address_for_reply_to: false,
        reply_to_address: "replies@replies.test"
      )

      configuration = described_class.resolve!(domain)

      expect(configuration.reply_to).to eq("replies@replies.test")
    end

    it "logs and raises when the domain is inactive" do
      domain = create(:domain, :with_outbound_configuration, active: false)

      allow(Rails.logger).to receive(:error)

      expect {
        described_class.resolve!(domain)
      }.to raise_error(Outbound::ConfigurationError, /domain must be active/)

      expect(Rails.logger).to have_received(:error).with(/#{Regexp.escape(domain.name)}/)
    end

    it "does not log smtp secrets when configuration is incomplete" do
      domain = build(
        :domain,
        :with_outbound_configuration,
        smtp_host: nil,
        smtp_password: "super-secret-password"
      )

      logged_message = nil
      allow(Rails.logger).to receive(:error) { |message| logged_message = message }

      expect {
        described_class.resolve!(domain)
      }.to raise_error(Outbound::ConfigurationError, /smtp_host can't be blank/)

      expect(logged_message).not_to include("super-secret-password")
    end
  end
end
