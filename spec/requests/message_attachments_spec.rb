require "rails_helper"

RSpec.describe "MessageAttachments", type: :request do
  describe "GET /messages/:message_id/attachments/:id" do
    it "renders previewable inbound attachments inline" do
      user = create(:user)
      login_user(user)
      message = create(:message)
      message.attachments.attach(
        io: StringIO.new("image-bytes"),
        filename: "preview.png",
        content_type: "image/png"
      )

      get message_attachment_path(message, message.attachments.first)

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.body).to eq("image-bytes")
    end

    it "downloads inbound attachments explicitly" do
      user = create(:user)
      login_user(user)
      message = create(:message)
      message.attachments.attach(
        io: StringIO.new("pdf-bytes"),
        filename: "preview.pdf",
        content_type: "application/pdf"
      )

      get download_message_attachment_path(message, message.attachments.first)

      expect(response).to have_http_status(:success)
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.body).to eq("pdf-bytes")
    end
  end
end
