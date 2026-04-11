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

  def current_app_switcher_link_class(area)
    token_list(
      "border px-3 py-1 font-mono text-[0.62rem] uppercase tracking-widest transition-colors",
      (current_product_area.to_sym == area.to_sym) ? "border-amber bg-amber/10 text-amber glow-amber" : "border-hairline text-phosphor-dim hover:border-phosphor hover:text-phosphor"
    )
  end
end
