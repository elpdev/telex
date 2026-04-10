module InboxesHelper
  SEARCH_KEYS = %i[status_eq subaddress_eq subject_or_from_address_or_from_name_or_text_body_cont].freeze

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
end
