module ApplicationHelper
  def command_palette_domains
    return [] unless Current.user

    Domain.order(:name).to_a
  end

  def command_palette_inboxes
    return [] unless Current.user

    Inbox.includes(:domain).sort_by { |inbox| [inbox.domain.name, inbox.address] }
  end

  def command_palette_labels
    return [] unless Current.user

    Current.user.labels.order(:name).to_a
  end

  def command_palette_global_suggestions
    [
      {label: "go mail", href: root_path(mailbox: "inbox"), hint: "APP", group: "go"},
      {label: "go calendar", href: calendar_path, hint: "APP", group: "go"},
      {label: "go profile", href: profile_path, hint: "ACCOUNT", group: "go"},
      {label: "go api keys", href: api_keys_path, hint: "API KEYS", group: "go"},
      {label: "go notifications", href: notifications_path, hint: "NOTIFICATIONS", group: "go"},
      {label: "sign out", href: session_path, hint: "DESTROY SESSION", group: "action", method: "delete"}
    ]
  end
end
