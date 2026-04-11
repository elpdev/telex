class API::V1::MessageInlineAssetsController < API::V1::BaseController
  def show
    message = Message.find(params[:id])
    part = message.inline_part_for_token(params[:token])
    return head :not_found if part.nil?

    send_data part.body.decoded, type: part.mime_type || "application/octet-stream", disposition: :inline
  end
end
