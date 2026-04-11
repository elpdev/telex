require "rails_helper"

RSpec.describe "EmailTemplates", type: :request do
  let(:user) { create(:user) }
  let(:domain) { create(:domain, :with_outbound_configuration, name: "example.test") }

  before { login_user(user) }

  describe "GET /email_templates" do
    it "lists templates" do
      create(:email_template, domain: domain, name: "Password reset")

      get email_templates_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Password reset")
      expect(response.body).to include(domain.name)
    end

    it "renders an empty state when no templates exist" do
      get email_templates_path

      expect(response.body).to include("no templates yet")
    end

    it "requires authentication" do
      delete session_path
      get email_templates_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "POST /email_templates" do
    it "creates a template" do
      expect {
        post email_templates_path, params: {
          email_template: {
            name: "Welcome",
            domain_id: domain.id,
            subject: "Welcome to the team",
            body: "<div>Welcome!</div>"
          }
        }
      }.to change(EmailTemplate, :count).by(1)

      template = EmailTemplate.last
      expect(template.name).to eq("Welcome")
      expect(template.subject).to eq("Welcome to the team")
      expect(template.body.to_plain_text).to include("Welcome!")
      expect(response).to redirect_to(email_templates_path)
    end

    it "re-renders the form when name is blank" do
      post email_templates_path, params: {
        email_template: {name: "", domain_id: domain.id, body: "<div>hi</div>"}
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("blocked save")
    end

    it "rejects duplicate names within the same domain" do
      create(:email_template, domain: domain, name: "Welcome")

      post email_templates_path, params: {
        email_template: {name: "Welcome", domain_id: domain.id, body: "<div>hi</div>"}
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /email_templates/:id" do
    it "updates a template" do
      template = create(:email_template, domain: domain, name: "Old")

      patch email_template_path(template), params: {
        email_template: {name: "New", domain_id: domain.id, body: "<div>new</div>"}
      }

      expect(response).to redirect_to(email_templates_path)
      expect(template.reload.name).to eq("New")
    end
  end

  describe "DELETE /email_templates/:id" do
    it "deletes the template" do
      template = create(:email_template, domain: domain)

      expect {
        delete email_template_path(template)
      }.to change(EmailTemplate, :count).by(-1)

      expect(response).to redirect_to(email_templates_path)
    end
  end
end
