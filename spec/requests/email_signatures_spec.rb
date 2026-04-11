require "rails_helper"

RSpec.describe "EmailSignatures", type: :request do
  let(:user) { create(:user) }
  let(:domain) { create(:domain, :with_outbound_configuration, name: "example.test") }

  before { login_user(user) }

  describe "GET /email_signatures" do
    it "lists signatures" do
      create(:email_signature, domain: domain, name: "Support sign-off")

      get email_signatures_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Support sign-off")
      expect(response.body).to include(domain.name)
    end

    it "renders an empty state when no signatures exist" do
      get email_signatures_path

      expect(response.body).to include("no signatures yet")
    end

    it "requires authentication" do
      delete session_path
      get email_signatures_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "POST /email_signatures" do
    it "creates a signature" do
      expect {
        post email_signatures_path, params: {
          email_signature: {
            name: "Support",
            domain_id: domain.id,
            is_default: "1",
            body: "<div>-- Support</div>"
          }
        }
      }.to change(EmailSignature, :count).by(1)

      signature = EmailSignature.last
      expect(signature.name).to eq("Support")
      expect(signature).to be_is_default
      expect(signature.body.to_plain_text).to include("Support")
      expect(response).to redirect_to(email_signatures_path)
    end

    it "re-renders the form when name is blank" do
      post email_signatures_path, params: {
        email_signature: {name: "", domain_id: domain.id, body: "<div>hi</div>"}
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("blocked save")
    end
  end

  describe "PATCH /email_signatures/:id" do
    it "updates a signature" do
      signature = create(:email_signature, domain: domain, name: "Old")

      patch email_signature_path(signature), params: {
        email_signature: {name: "New", domain_id: domain.id, body: "<div>new body</div>"}
      }

      expect(response).to redirect_to(email_signatures_path)
      expect(signature.reload.name).to eq("New")
    end

    it "promoting a signature to default demotes the existing default" do
      original = create(:email_signature, domain: domain, is_default: true)
      other = create(:email_signature, domain: domain, is_default: false)

      patch email_signature_path(other), params: {
        email_signature: {name: other.name, domain_id: domain.id, is_default: "1", body: "x"}
      }

      expect(other.reload).to be_is_default
      expect(original.reload).not_to be_is_default
    end
  end

  describe "DELETE /email_signatures/:id" do
    it "deletes the signature" do
      signature = create(:email_signature, domain: domain)

      expect {
        delete email_signature_path(signature)
      }.to change(EmailSignature, :count).by(-1)

      expect(response).to redirect_to(email_signatures_path)
    end
  end
end
