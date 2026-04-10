require "rails_helper"

RSpec.describe "MessageBodies", type: :request do
  describe "GET /messages/:id/body" do
    it "redirects signed out users to login" do
      message = create(:message)

      get body_message_path(message)

      expect(response).to redirect_to(new_session_path)
    end

    it "renders the raw inbound html for html emails" do
      user = create(:user)
      login_user(user)
      inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(<<~EMAIL)
        From: Sender <sender@example.com>
        To: html@test.dev
        Subject: Styled html
        Message-ID: <styled-html@test.dev>
        Date: Fri, 10 Apr 2026 10:00:00 +0000
        MIME-Version: 1.0
        Content-Type: text/html; charset=UTF-8

        <html><head><style>body { background: #fff; color: #123456; }</style></head><body><table><tr><td><strong>Hello iframe</strong></td></tr></table></body></html>
      EMAIL
      message = create(:message, inbound_email: inbound_email, text_body: "Hello iframe")

      get body_message_path(message)

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("text/html")
      expect(response.body).to include("<style>body { background: #fff; color: #123456; }</style>")
      expect(response.body).to include("<strong>Hello iframe</strong>")
      expect(response.body).to include("<base target=\"_blank\">")
      expect(response.body).to include("message-body:resize")
    end

    it "rewrites cid image sources to inline asset routes" do
      user = create(:user)
      login_user(user)
      inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(<<~EMAIL)
        From: Sender <sender@example.com>
        To: html@test.dev
        Subject: Inline image
        Message-ID: <inline-image@test.dev>
        Date: Fri, 10 Apr 2026 10:00:00 +0000
        MIME-Version: 1.0
        Content-Type: multipart/related; boundary="boundary"

        --boundary
        Content-Type: text/html; charset=UTF-8

        <html><body><img src="cid:hero-image"></body></html>
        --boundary
        Content-Type: image/png
        Content-Transfer-Encoding: base64
        Content-ID: <hero-image>
        Content-Disposition: inline; filename="hero.png"

        aGVsbG8=
        --boundary--
      EMAIL
      message = create(:message, inbound_email: inbound_email, text_body: "Inline image")

      get body_message_path(message)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(inline_asset_message_path(message, token: message.inline_asset_token("hero-image")))
      expect(response.body).not_to include("cid:hero-image")
    end

    it "renders plain text inside a standalone document when no html part exists" do
      user = create(:user)
      login_user(user)
      message = create(:message, text_body: "Plain text only")

      get body_message_path(message)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Plain text only")
      expect(response.body).to include("font-family: ui-monospace")
    end
  end

  describe "GET /messages/:id/inline_assets/:token" do
    it "serves inline mime parts for authenticated users" do
      user = create(:user)
      login_user(user)
      inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(<<~EMAIL)
        From: Sender <sender@example.com>
        To: html@test.dev
        Subject: Inline asset
        Message-ID: <inline-asset@test.dev>
        Date: Fri, 10 Apr 2026 10:00:00 +0000
        MIME-Version: 1.0
        Content-Type: multipart/related; boundary="boundary"

        --boundary
        Content-Type: text/html; charset=UTF-8

        <html><body><img src="cid:hero-image"></body></html>
        --boundary
        Content-Type: image/png
        Content-Transfer-Encoding: base64
        Content-ID: <hero-image>
        Content-Disposition: inline; filename="hero.png"

        aGVsbG8=
        --boundary--
      EMAIL
      message = create(:message, inbound_email: inbound_email, text_body: "Inline asset")

      get inline_asset_message_path(message, token: message.inline_asset_token("hero-image"))

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("image/png")
      expect(response.body).to eq("hello")
    end
  end
end
