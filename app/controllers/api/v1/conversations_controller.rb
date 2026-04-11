class API::V1::ConversationsController < API::V1::BaseController
  before_action :set_conversation, only: [:show, :timeline, :archive, :restore, :trash, :labels]

  def index
    scope = Conversation.includes(:messages, :outbound_messages)
    scope = scope.joins(:messages).where(messages: {inbox_id: params[:inbox_id]}).distinct if params[:inbox_id].present?
    scope = scope.in_mailbox_for(current_user, params[:mailbox]) if params[:mailbox].present?
    scope = scope.with_label_for(current_user, params[:label_id]) if params[:label_id].present?
    scope = apply_query(scope)
    scope = apply_sort(scope, allowed: %w[created_at last_message_at updated_at], default: :last_message_at)

    records, meta = paginate(scope)
    render_data(records.map { |conversation| API::V1::Serializers.conversation(conversation, current_user: current_user) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.conversation(@conversation, current_user: current_user))
  end

  def timeline
    entries = @conversation.timeline_entries.map do |entry|
      API::V1::Serializers.conversation_timeline_entry(entry)
    end

    render_data(entries)
  end

  def archive
    @conversation.move_to_state_for(current_user, :archived)
    render_data(API::V1::Serializers.conversation(@conversation, current_user: current_user))
  end

  def restore
    @conversation.move_to_state_for(current_user, :inbox)
    render_data(API::V1::Serializers.conversation(@conversation, current_user: current_user))
  end

  def trash
    @conversation.move_to_state_for(current_user, :trash)
    render_data(API::V1::Serializers.conversation(@conversation, current_user: current_user))
  end

  def labels
    @conversation.assign_labels_for(current_user, params[:label_ids])
    render_data(API::V1::Serializers.conversation(@conversation.reload, current_user: current_user))
  end

  private

  def set_conversation
    @conversation = Conversation.includes(:messages, :outbound_messages).find(params[:id])
  end

  def apply_query(scope)
    query = params[:q].to_s.strip
    return scope if query.blank?

    scope.where("subject_key LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(query)}%")
  end
end
