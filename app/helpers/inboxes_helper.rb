module InboxesHelper
  SEARCH_KEYS = %i[query sender recipient received_from received_to status subaddress].freeze

  def inbox_browser_params(overrides = {}, except: [])
    current = params.permit(:inbox_id, :message_id, :page, :outbound_message_id, q: SEARCH_KEYS).to_h.deep_dup
    except.map!(&:to_s)

    except.each do |key|
      current.delete(key)
    end

    if except.include?("q")
      current.delete("q")
    end

    current.deep_merge(overrides.deep_stringify_keys)
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
