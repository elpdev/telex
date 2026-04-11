require "rails_helper"

RSpec.describe "Registrations", type: :request do
  before do
    Flipper.disable(:sign_up)
  end

  describe "GET /registration/new" do
    context "when sign up is enabled" do
      before do
        Flipper.enable(:sign_up)
      end

      it "renders the registration page" do
        get new_registration_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("CREATE IDENTITY")
      end
    end

    context "when sign up is disabled" do
      it "redirects to the root path" do
        get new_registration_path

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /registration" do
    let(:params) do
      {
        user: {
          email_address: "new-user@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    context "when sign up is enabled" do
      before do
        Flipper.enable(:sign_up)
      end

      it "creates a user" do
        expect {
          post registration_path, params: params
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_url)
      end
    end

    context "when sign up is disabled" do
      it "does not create a user" do
        expect {
          post registration_path, params: params
        }.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "public registration links" do
    it "hides the registration links on the landing page when sign up is disabled" do
      get welcome_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(new_registration_path)
    end

    it "hides the registration link on the sign in page when sign up is disabled" do
      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(new_registration_path)
    end
  end
end
