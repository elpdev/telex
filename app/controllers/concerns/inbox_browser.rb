module InboxBrowser
  extend ActiveSupport::Concern

  private

  def load_inbox_browser(selected_inbox_id: nil, selected_message_id: nil)
    @inboxes = Inbox
      .active
      .left_joins(:messages)
      .select("inboxes.*, COUNT(messages.id) AS message_count")
      .group("inboxes.id")
      .order(:address)
      .to_a

    @selected_inbox = if selected_inbox_id.present?
      @inboxes.find { |inbox| inbox.id == selected_inbox_id.to_i }
    elsif params[:inbox_id].present?
      @inboxes.find { |inbox| inbox.id == params[:inbox_id].to_i }
    end

    @all_inboxes_count = Message.joins(:inbox).merge(Inbox.active).count
    @drafts = Current.user.outbound_messages.drafts.includes(:source_message, :domain).limit(12)

    scope = Message
      .joins(:inbox)
      .merge(Inbox.active)
      .includes(inbox: :domain, conversation: {outbound_messages: :domain})
      .with_rich_text_body
      .with_attached_attachments
      .newest_first

    scope = scope.where(inbox: @selected_inbox) if @selected_inbox.present?

    @q = search_params
    filtered_scope = Message.apply_search_filters(scope, @q)
    @pagy, paginated_scope = pagy(filtered_scope, limit: 18)
    @messages = paginated_scope.to_a
    @selected_message = if selected_message_id.present?
      @messages.find { |message| message.id == selected_message_id.to_i } || filtered_scope.find_by(id: selected_message_id)
    elsif params[:message_id].present?
      @messages.find { |message| message.id == params[:message_id].to_i } || filtered_scope.find_by(id: params[:message_id])
    else
      @messages.first
    end
    @selected_message ||= @messages.first
    @thread_timeline = @selected_message&.conversation&.timeline_entries || []
  end

  def search_params
    params.fetch(:q, {}).permit(:query, :sender, :recipient, :received_from, :received_to, :status, :subaddress).to_h
  end
end
