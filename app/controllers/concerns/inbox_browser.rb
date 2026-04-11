module InboxBrowser
  extend ActiveSupport::Concern

  private

  def load_inbox_browser(selected_inbox_id: nil, selected_message_id: nil)
    @inboxes = Inbox
      .with_message_count_for(user: Current.user)
      .active
      .includes(:domain)
      .order("domains.name, inboxes.address")
      .to_a

    @domains = @inboxes.map(&:domain).uniq(&:id).sort_by(&:name)

    @labels = Current.user.labels.order(:name).to_a
    @selected_label = @labels.find { |label| label.id == params[:label_id].to_i } if params[:label_id].present?
    @mailbox = normalized_mailbox
    @mailbox_counts = mailbox_counts

    @selected_inbox = if selected_inbox_id.present?
      @inboxes.find { |inbox| inbox.id == selected_inbox_id.to_i }
    elsif params[:inbox_id].present?
      @inboxes.find { |inbox| inbox.id == params[:inbox_id].to_i }
    end

    @selected_domain = if params[:domain_id].present?
      @domains.find { |domain| domain.id == params[:domain_id].to_i }
    end

    @all_inboxes_count = @inboxes.sum(&:message_count)
    @drafts = Current.user.outbound_messages.drafts.includes(:source_message, :domain).limit(12)

    if @mailbox == "sent"
      load_sent_browser
      return
    end

    if @mailbox == "drafts"
      load_drafts_browser
      return
    end

    scope = Message
      .joins(:inbox)
      .merge(Inbox.active)
      .includes(:message_organizations, :labels, inbox: :domain, conversation: [{outbound_messages: :domain}, {conversation_organizations: :labels}])
      .with_rich_text_body
      .with_attached_attachments
      .newest_first

    scope = scope.where(inbox: @selected_inbox) if @selected_inbox.present?
    scope = scope.joins(inbox: :domain).where(inboxes: {domain_id: @selected_domain.id}) if @selected_domain.present? && @selected_inbox.blank?
    scope = scope.in_mailbox_for(Current.user, @mailbox)
    scope = scope.reorder(Arel.sql("CASE WHEN message_organizations.read_at IS NULL THEN 0 ELSE 1 END ASC, messages.received_at DESC, messages.id DESC")) if @mailbox == "inbox"
    scope = scope.with_label_for(Current.user, @selected_label.id) if @selected_label.present?

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
    @selected_message&.mark_read_for(Current.user)
    @selected_sent_message = nil
    @selected_conversation = @selected_message&.conversation
    @thread_timeline = @selected_message&.conversation&.timeline_entries || []
  end

  def search_params
    params.fetch(:q, {}).permit(:query, :sender, :recipient, :received_from, :received_to, :status, :subaddress).to_h
  end

  def normalized_mailbox
    mailbox = params[:mailbox].to_s
    InboxesHelper::MAILBOXES.include?(mailbox) ? mailbox : "inbox"
  end

  def mailbox_counts
    {
      "inbox" => Message.in_mailbox_for(Current.user, "inbox").joins(:inbox).merge(Inbox.active).count,
      "junk" => Message.in_mailbox_for(Current.user, "junk").joins(:inbox).merge(Inbox.active).count,
      "archived" => Message.in_mailbox_for(Current.user, "archived").joins(:inbox).merge(Inbox.active).count,
      "trash" => Message.in_mailbox_for(Current.user, "trash").joins(:inbox).merge(Inbox.active).count,
      "sent" => Current.user.outbound_messages.sent.count,
      "drafts" => Current.user.outbound_messages.draft.count
    }
  end

  def load_drafts_browser
    scope = Current.user.outbound_messages.drafts
      .includes(:source_message, :domain, conversation: [{messages: {inbox: :domain}}, :outbound_messages])
      .with_rich_text_body

    search = params.dig(:q, :query).to_s.strip
    if search.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(search)}%"
      scope = scope.where("subject LIKE ?", like)
    end

    @q = {query: search}.compact_blank
    @pagy, paginated_scope = pagy(scope, limit: 18)
    @messages = paginated_scope.to_a

    # When a specific draft is requested, the controller loads it as
    # @outbound_message. Otherwise auto-select the first draft so the
    # composer opens immediately on entering the drafts view.
    @auto_select_first_draft = params[:outbound_message_id].blank? && @messages.first.present?
    @selected_message = nil
    @selected_sent_message = nil
    @selected_conversation = nil
    @thread_timeline = []
  end

  def load_sent_browser
    scope = Current.user.outbound_messages.sent.includes(:domain, conversation: [{messages: {inbox: :domain}}, :outbound_messages]).with_rich_text_body.newest_first
    search = params.dig(:q, :query).to_s.strip

    if search.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(search)}%"
      scope = scope.where("subject LIKE ?", like)
    end

    @q = {query: search}.compact_blank
    @pagy, paginated_scope = pagy(scope, limit: 18)
    @messages = paginated_scope.to_a
    @selected_sent_message = if params[:sent_message_id].present?
      @messages.find { |message| message.id == params[:sent_message_id].to_i } || scope.find_by(id: params[:sent_message_id])
    else
      @messages.first
    end
    @selected_message = nil
    @selected_conversation = @selected_sent_message&.conversation
    @thread_timeline = @selected_conversation&.timeline_entries || []
  end
end
