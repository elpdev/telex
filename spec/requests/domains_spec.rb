require "rails_helper"

RSpec.describe "Domains", type: :request do
  let(:user) { create(:user) }

  before { login_user(user) }

  describe "GET /domains" do
    it "lists domains in the settings shell" do
      domain = create(:domain, :with_outbound_configuration, name: "example.test", user: user)
      create(:inbox, domain: domain, local_part: "support")

      get domains_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Domains")
      expect(response.body).to include(domain.name)
      expect(response.body).to include("1 inbox")
      expect(response.body).to include("MANAGE")
      expect(response.body).to include("support@example.test")
    end

    it "requires authentication" do
      delete session_path

      get domains_path

      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /domains/:id" do
    it "shows the domain and its inboxes" do
      domain = create(:domain, name: "example.test", user: user)
      inbox = create(:inbox, domain: domain, local_part: "billing", description: "Invoice triage")

      get domain_path(domain)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(domain.name)
      expect(response.body).to include(inbox.address)
      expect(response.body).to include("Invoice triage")
    end
  end

  describe "POST /domains" do
    it "creates a domain" do
      expect {
        post domains_path, params: {
          domain: {
            name: "example.test",
            active: "1",
            outbound_from_name: "Telex",
            outbound_from_address: "hello@example.test",
            use_from_address_for_reply_to: "1",
            smtp_host: "smtp.example.test",
            smtp_port: 587,
            smtp_authentication: "login",
            smtp_enable_starttls_auto: "1",
            smtp_username: "smtp-user",
            smtp_password: "smtp-pass"
          }
        }
      }.to change(Domain, :count).by(1)

      domain = Domain.last
      expect(domain.name).to eq("example.test")
      expect(response).to redirect_to(domain_path(domain))
    end

    it "re-renders when invalid" do
      post domains_path, params: {
        domain: {name: "", smtp_port: 0}
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("blocked save")
    end
  end

  describe "PATCH /domains/:id" do
    it "updates the domain" do
      domain = create(:domain, name: "example.test", user: user)

      patch domain_path(domain), params: {
        domain: {
          name: "mail.example.test",
          active: "0"
        }
      }

      expect(response).to redirect_to(domain_path(domain))
      expect(domain.reload.name).to eq("mail.example.test")
      expect(domain).not_to be_active
    end
  end

  describe "DELETE /domains/:id" do
    it "deletes the domain" do
      domain = create(:domain, user: user)

      expect {
        delete domain_path(domain)
      }.to change(Domain, :count).by(-1)

      expect(response).to redirect_to(domains_path)
    end
  end
end
