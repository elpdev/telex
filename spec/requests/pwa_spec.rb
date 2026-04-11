require "rails_helper"

RSpec.describe "PWA", type: :request do
  describe "GET /manifest.json" do
    it "serves the web app manifest" do
      get pwa_manifest_path

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")
      expect(response.body).to include('"name": "Telex"')
      expect(response.body).to include('"src": "/favicon/web-app-manifest-192x192.png"')
      expect(response.body).to include('"src": "/favicon/web-app-manifest-512x512.png"')
      expect(response.body).not_to include("favicon.svg")
      expect(response.body).to include('"display": "standalone"')
    end
  end

  describe "GET /service-worker.js" do
    it "serves the service worker" do
      get pwa_service_worker_path

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("text/javascript")
      expect(response.body).to include('const CACHE_NAME = "telex-v1";')
      expect(response.body).to include("self.addEventListener(\"fetch\"")
    end
  end
end
