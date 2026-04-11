class API::V1::MessagesController < API::V1::BaseController
  before_action :set_message, only: [:show, :body, :reply, :reply_all, :forward, :junk, :not_junk, :archive, :restore, :trash, :labels, :mark_read, :mark_unread, :star, :unstar, :block_sender, :unblock_sender, :block_domain, :unblock_domain, :trust_sender, :untrust_sender]

  def index
    scope = Message.includes(:inbox, :conversation).with_attached_attachments.with_rich_text_body
    scope = scope.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?
    scope = scope.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    scope = scope.in_mailbox_for(current_user, params[:mailbox]) if params[:mailbox].present?
    scope = scope.with_label_for(current_user, params[:label_id]) if params[:label_id].present?
    scope = Message.apply_search_filters(scope, search_filters)
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

  def junk
    @message.move_to_junk_for(current_user)
    render_data(API::V1::Serializers.message(@message.reload, current_user: current_user))
  end

  def not_junk
    @message.restore_to_inbox_for(current_user)
    render_data(API::V1::Serializers.message(@message.reload, current_user: current_user))
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

  def mark_read
    @message.mark_read_for(current_user)
    render_data(API::V1::Serializers.message(@message.reload, current_user: current_user))
  end

  def mark_unread
    @message.mark_unread_for(current_user)
    render_data(API::V1::Serializers.message(@message.reload, current_user: current_user))
  end

  def star
    @message.set_starred_for(current_user, true)
    render_data(API::V1::Serializers.message(@message.reload, current_user: current_user))
  end

  def unstar
    @message.set_starred_for(current_user, false)
    render_data(API::V1::Serializers.message(@message.reload, current_user: current_user))
  end

  def block_sender
    render_sender_policy(:sender, :blocked)
  end

  def unblock_sender
    clear_sender_policy(:sender)
  end

  def block_domain
    render_sender_policy(:domain, :blocked)
  end

  def unblock_domain
    clear_sender_policy(:domain)
  end

  def trust_sender
    render_sender_policy(:sender, :trusted)
  end

  def untrust_sender
    clear_sender_policy(:sender, disposition: :trusted)
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

  def render_sender_policy(target_kind, disposition)
    value = sender_policy_value(target_kind)
    SenderPolicy.clear!(user: current_user, target_kind: target_kind, value: value)
    SenderPolicy.set!(user: current_user, target_kind: target_kind, value: value, disposition: disposition)
    render_data(API::V1::Serializers.message(@message.reload, current_user: current_user))
  end

  def clear_sender_policy(target_kind, disposition: nil)
    value = sender_policy_value(target_kind)
    scope = current_user.sender_policies.where(kind: target_kind, value: value)
    scope = scope.where(disposition: disposition) if disposition.present?
    scope.destroy_all
    render_data(API::V1::Serializers.message(@message.reload, current_user: current_user))
  end

  def sender_policy_value(target_kind)
    case target_kind.to_sym
    when :sender
      @message.from_address.to_s.strip.downcase
    when :domain
      @message.sender_domain.to_s
    end
  end
end
