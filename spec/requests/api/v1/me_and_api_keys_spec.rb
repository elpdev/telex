require "rails_helper"

RSpec.describe "API::V1::MeAndApiKeys", type: :request do
  let(:user) { create(:user, name: "Leo") }
  let(:headers) { api_headers_for(user) }

  describe "GET /api/v1/me" do
    it "returns the current user" do
      get "/api/v1/me", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.dig("data", "email_address")).to eq(user.email_address)
      expect(json.dig("data", "name")).to eq("Leo")
    end
  end

  describe "PATCH /api/v1/me" do
    it "updates the current user" do
      patch "/api/v1/me", params: {
        user: {
          name: "Updated",
          email_address: "updated@example.com"
        }
      }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.name).to eq("Updated")
      expect(user.email_address).to eq("updated@example.com")
    end
  end

  describe "GET /api/v1/api_keys" do
    it "lists only the current user's keys" do
      own_key = create(:api_key, user: user, name: "Own key")
      create(:api_key, name: "Other key")

      get "/api/v1/api_keys", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      names = json["data"].map { |entry| entry["name"] }
      expect(names).to include(own_key.name)
      expect(names).not_to include("Other key")
    end
  end

  describe "POST /api/v1/api_keys" do
    it "creates an API key and returns the secret once" do
      post "/api/v1/api_keys", params: {
        api_key: {
          name: "Agent key"
        }
      }, headers: headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json.dig("data", "name")).to eq("Agent key")
      expect(json.dig("data", "secret_key")).to be_present
    end
  end
end
