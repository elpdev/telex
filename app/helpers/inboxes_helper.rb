module InboxesHelper
  COMMAND_PALETTE_QUERY_PLACEHOLDER = "COMMAND_PALETTE_QUERY".freeze
  SEARCH_KEYS = %i[query sender recipient received_from received_to status subaddress].freeze
  MAILBOXES = %w[inbox junk sent drafts archived trash].freeze
  INBOX_SORT_OPTIONS = %w[unread newest oldest].freeze
  CHRONOLOGICAL_SORT_OPTIONS = %w[newest oldest].freeze
  COMMAND_PALETTE_TRANSIENT_KEYS = %i[
    message_id
    sent_message_id
    outbound_message_id
    page
    attachment_id
    outbound_attachment_id
    sent_attachment_id
  ].freeze

  def inbox_browser_params(overrides = {}, except: [])
    current = params.permit(:inbox_id, :domain_id, :message_id, :page, :outbound_message_id, :mailbox, :label_id, :sent_message_id, :attachment_id, :outbound_attachment_id, :sent_attachment_id, :sort, q: SEARCH_KEYS).to_h.deep_dup
    except = except.map(&:to_s)

    except.each do |key|
      current.delete(key)
    end

    if except.include?("q")
      current.delete("q")
    end

    current.deep_merge(overrides.deep_stringify_keys)
  end

  def command_palette_search_href(query = COMMAND_PALETTE_QUERY_PLACEHOLDER)
    query = query.to_s

    if controller_name == "inboxes" && action_name == "index"
      search_filters = params.fetch(:q, {}).permit(*SEARCH_KEYS).to_h.symbolize_keys
      preserved_filters = search_filters.merge(query: query).compact_blank

      return root_path(
        inbox_browser_params(
          {q: preserved_filters},
          except: COMMAND_PALETTE_TRANSIENT_KEYS
        )
      )
    end

    root_path(mailbox: "inbox", q: {query: query})
  end

  def active_mailbox?(mailbox, current_mailbox)
    current_mailbox.to_s == mailbox.to_s
  end

  def inbox_sort_options(mailbox)
    (mailbox.to_s == "inbox") ? INBOX_SORT_OPTIONS : CHRONOLOGICAL_SORT_OPTIONS
  end

  def inbox_sort_label(sort)
    case sort.to_s
    when "oldest"
      "oldest"
    when "unread"
      "unread"
    else
      "newest"
    end
  end

  def organization_state_variant(system_state)
    case system_state
    when "archived"
      :warning
    when "junk"
      :warning
    when "trash"
      :danger
    else
      :default
    end
  end

  def selected_label?(label, selected_label)
    label.present? && selected_label.present? && label.id == selected_label.id
  end

  def message_status_variant(message)
    case message.status
    when "processed"
      :success
    when "failed"
      :danger
    when "processing"
      :warning
    else
      :default
    end
  end

  def relative_message_time(message)
    return "just now" if message.received_at.blank?

    "#{time_ago_in_words(message.received_at)} ago"
  end

  def recipient_list(addresses)
    Array(addresses).reject(&:blank?).join(", ")
  end

  def compose_kind(outbound_message)
    return "compose" if outbound_message.nil?
    return "forward" if outbound_message.metadata["draft_kind"] == "forward"
    return "reply" if outbound_message.source_message.present?

    outbound_message.metadata["draft_kind"].presence || "compose"
  end

  def compose_sender_identity(outbound_message)
    domain = outbound_message.domain
    return "Sender domain not selected" unless domain.present?

    domain.outbound_identity&.fetch(:from) || domain.formatted_outbound_from
  rescue
    [domain&.outbound_from_name, domain&.outbound_from_address].compact.join(" ").presence || domain&.name || "Sender not configured"
  end

  def compose_sender_context(outbound_message)
    if outbound_message.source_message.present?
      "Sending from #{outbound_message.source_message.inbox.address}"
    elsif outbound_message.domain.present?
      "Sending from #{outbound_message.domain.name}"
    else
      "No sender domain selected"
    end
  end

  def compose_reply_to_hint(outbound_message)
    domain = outbound_message.domain
    return unless domain.present?
    return if domain.resolved_reply_to_address.blank? || domain.resolved_reply_to_address == domain.outbound_from_address

    "Replies go to #{domain.resolved_reply_to_address}"
  end

  def compose_send_ready?(outbound_message)
    outbound_message.domain&.outbound_ready? || false
  end

  def compose_send_warning(outbound_message)
    domain = outbound_message.domain
    return "No sender domain selected for this draft." unless domain.present?
    return if domain.outbound_ready?

    "#{domain.name} is not ready to send: #{domain.outbound_configuration_errors.join(", ")}"
  end

  def compose_draft_label(outbound_message)
    case compose_kind(outbound_message)
    when "forward"
      "Forward"
    when "reply"
      "Reply"
    else
      "Draft"
    end
  end
end
