require "rails_helper"

RSpec.describe "API::V1::NotificationsAndMeta", type: :request do
  let(:user) { create(:user) }
  let(:headers) { api_headers_for(user) }

  describe "notifications" do
    it "lists notifications and marks them read" do
      WelcomeNotifier.with({}).deliver(user)
      notification = user.notifications.last

      get "/api/v1/notifications", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", 0, "id")).to eq(notification.id)

      patch "/api/v1/notifications/#{notification.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(notification.reload.read_at).to be_present

      post "/api/v1/notifications/mark_all_read", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "meta endpoints" do
    it "returns pipelines, capabilities, and health" do
      get "/api/v1/pipelines", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("data")).not_to be_empty

      get "/api/v1/capabilities", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "resources", "messages")).to include("reply")
      expect(JSON.parse(response.body).dig("data", "resources", "labels")).to include("create")
      expect(JSON.parse(response.body).dig("data", "resources", "direct_uploads")).to include("create")
      expect(JSON.parse(response.body).dig("data", "resources", "files")).to include("upload", "download")
      expect(JSON.parse(response.body).dig("data", "filters", "messages")).to include("mailbox", "label_id")

      get "/api/v1/health"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "status")).to eq("ok")
    end
  end
end
