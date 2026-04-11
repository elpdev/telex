require "rails_helper"

RSpec.describe "OutboundMessageAttachments", type: :request do
  describe "GET /outbound_messages/:outbound_message_id/attachments/:id" do
    it "renders current user draft attachments inline" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: user)
      outbound_message.attachments.attach(
        io: StringIO.new("image-bytes"),
        filename: "draft.png",
        content_type: "image/png"
      )

      get outbound_message_attachment_path(outbound_message, outbound_message.attachments.first)

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.body).to eq("image-bytes")
    end

    it "downloads current user draft attachments" do
      user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: user)
      outbound_message.attachments.attach(
        io: StringIO.new("draft-pdf"),
        filename: "draft.pdf",
        content_type: "application/pdf"
      )

      get download_outbound_message_attachment_path(outbound_message, outbound_message.attachments.first)

      expect(response).to have_http_status(:success)
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.body).to eq("draft-pdf")
    end

    it "does not allow reading another user's draft attachments" do
      user = create(:user)
      other_user = create(:user)
      login_user(user)
      outbound_message = create(:outbound_message, user: other_user)
      outbound_message.attachments.attach(
        io: StringIO.new("secret"),
        filename: "secret.pdf",
        content_type: "application/pdf"
      )

      get outbound_message_attachment_path(outbound_message, outbound_message.attachments.first)

      expect(response).to have_http_status(:not_found)
    end
  end
end
