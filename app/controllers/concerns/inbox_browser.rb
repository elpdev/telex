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

    @q = scope.ransack(search_params)
    filtered_scope = @q.result(distinct: true)
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
    permitted = params.fetch(:q, {}).permit(:status_eq, :subaddress_cont, :subject_or_from_address_or_from_name_or_text_body_cont).to_h

    if permitted["status_eq"].present?
      permitted["status_eq"] = Message.statuses[permitted["status_eq"]]
    end

    permitted
  end
end
