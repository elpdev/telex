class API::V1::MessagesController < API::V1::BaseController
  before_action :set_message, only: [:show, :body, :reply, :reply_all, :forward]

  def index
    scope = Message.includes(:inbox, :conversation).with_attached_attachments.with_rich_text_body
    scope = scope.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?
    scope = scope.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    scope = Message.apply_search_filters(scope, search_filters)
    scope = apply_sort(scope, allowed: %w[created_at received_at status subject], default: :received_at)

    records, meta = paginate(scope)
    render_data(records.map { |message| API::V1::Serializers.message(message) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.message(@message))
  end

  def body
    render_data({
      id: @message.id,
      html: @message.raw_html_body,
      text: @message.text_body,
      html_email: @message.html_email?
    })
  end

  def reply
    outbound_message = Outbound::ReplyBuilder.create!(@message)
    render_data(API::V1::Serializers.outbound_message(outbound_message), status: :created)
  end

  def reply_all
    outbound_message = Outbound::ReplyBuilder.create!(@message, reply_all: true)
    render_data(API::V1::Serializers.outbound_message(outbound_message), status: :created)
  end

  def forward
    outbound_message = Outbound::ForwardBuilder.create!(
      @message,
      target_addresses: Array(params[:target_addresses])
    )
    render_data(API::V1::Serializers.outbound_message(outbound_message), status: :created)
  end

  private

  def set_message
    @message = Message.includes(:inbox, :conversation).with_attached_attachments.with_rich_text_body.find(params[:id])
  end

  def search_filters
    {
      query: params[:q],
      sender: params[:sender],
      recipient: params[:recipient],
      status: params[:status],
      subaddress: params[:subaddress],
      received_from: params[:received_from],
      received_to: params[:received_to]
    }
  end
end
