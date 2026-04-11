class API::V1::MessagesController < API::V1::BaseController
  before_action :set_message, only: [:show, :body, :reply, :reply_all, :forward, :archive, :restore, :trash, :labels]

  def index
    scope = Message.includes(:inbox, :conversation).with_attached_attachments.with_rich_text_body
    scope = scope.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?
    scope = scope.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(subaddress: params[:subaddress]) if params[:subaddress].present?
    scope = scope.in_mailbox_for(current_user, params[:mailbox]) if params[:mailbox].present?
    scope = scope.with_label_for(current_user, params[:label_id]) if params[:label_id].present?
    scope = apply_query(scope)
    scope = apply_sort(scope, allowed: %w[created_at received_at status subject], default: :received_at)

    records, meta = paginate(scope)
    render_data(records.map { |message| API::V1::Serializers.message(message, current_user: current_user) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.message(@message, current_user: current_user))
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

  def archive
    @message.move_to_state_for(current_user, :archived)
    render_data(API::V1::Serializers.message(@message, current_user: current_user))
  end

  def restore
    @message.move_to_state_for(current_user, :inbox)
    render_data(API::V1::Serializers.message(@message, current_user: current_user))
  end

  def trash
    @message.move_to_state_for(current_user, :trash)
    render_data(API::V1::Serializers.message(@message, current_user: current_user))
  end

  def labels
    @message.assign_labels_for(current_user, params[:label_ids])
    render_data(API::V1::Serializers.message(@message.reload, current_user: current_user))
  end

  private

  def set_message
    @message = Message.includes(:inbox, :conversation).with_attached_attachments.with_rich_text_body.find(params[:id])
  end

  def apply_query(scope)
    query = params[:q].to_s.strip
    return scope if query.blank?

    like = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    scope.where(
      "subject LIKE :query OR from_address LIKE :query OR from_name LIKE :query OR text_body LIKE :query",
      query: like
    )
  end
end
