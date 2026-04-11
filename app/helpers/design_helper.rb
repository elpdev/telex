# frozen_string_literal: true

# Shared UI primitives for the Retrofuturist Display aesthetic.
# Used by views that don't warrant a full ViewComponent.
module DesignHelper
  # Wrap text in uppercase brackets: "compose" -> "[ COMPOSE ]"
  def bracket_label(text)
    "[ #{text.to_s.upcase} ]"
  end

  # Bracketed badge with hairline border + variant color.
  # variant: :phosphor, :amber, :cyan, :signal, :moss, :dim
  # By default the text is uppercased; pass preserve_case: true to keep it.
  def phosphor_badge(text, variant: :phosphor, extra: nil, preserve_case: false)
    classes = {
      phosphor: "border-phosphor text-phosphor",
      amber: "border-amber text-amber",
      cyan: "border-cyan text-cyan",
      signal: "border-signal text-signal",
      moss: "border-moss text-moss",
      dim: "border-hairline text-phosphor-dim"
    }
    display = preserve_case ? text.to_s : text.to_s.upcase
    tag.span("[#{display}]",
      class: token_list(
        "inline-flex items-center border px-1.5 py-0.5 font-mono text-[0.6rem] tracking-wider whitespace-nowrap",
        (preserve_case ? nil : "uppercase"),
        classes[variant] || classes[:phosphor],
        extra
      ))
  end

  # Monospace timestamp for message lists and thread headers.
  # Shows HH:MM for today, MON-DD for this year, YYYY-MM-DD for older.
  # Wrapped in a <time> element so the local_timestamp Stimulus controller
  # can rewrite the text in the browser's local timezone. The server-rendered
  # string acts as a progressive-enhancement fallback.
  def mono_timestamp(time)
    return "" if time.blank?
    now = Time.current
    server_text = if time.to_date == now.to_date
      time.strftime("%H:%M")
    elsif time.year == now.year
      time.strftime("%b %d").upcase
    else
      time.strftime("%Y-%m-%d")
    end
    tag.time(server_text, datetime: time.utc.iso8601, data: {controller: "local-timestamp"})
  end

  # ASCII divider of the given character width.
  def ascii_divider(length = 60, char: "-")
    tag.span(char * length, class: "ascii-divider text-hairline font-mono text-xs")
  end

  # Render a section label with a blinking cursor.
  # Example: > AGENT ACTIVITY _
  def terminal_prompt(text, variant: :phosphor)
    color = {
      phosphor: "text-phosphor",
      amber: "text-amber",
      cyan: "text-cyan",
      dim: "text-phosphor-dim"
    }[variant] || "text-phosphor"

    safe_join([
      tag.span("> ", class: "text-phosphor-dim font-mono"),
      tag.span(text.to_s.upcase, class: "font-mono uppercase tracking-widest #{color}"),
      tag.span(" _", class: "blink text-amber font-mono")
    ])
  end

  # Render a zero-padded line number for the code-editor gutter.
  def row_number(index)
    format("%02d", index.to_i)
  end

  # Label for a Mailbox (former "Inbox" model).
  # Returns "MAILBOX :: hello@lbp.dev"
  def mailbox_label(inbox)
    return "" if inbox.nil?
    "MAILBOX :: #{inbox.address}"
  end

  # Render a single action-rail keycap :: tight square button showing the
  # keyboard shortcut letter, with a CSS-only hover tooltip revealing the full
  # action label in the matching variant color.
  #
  # Interactive usage (default):
  #   keycap key: "R", label: "reply", path: reply_message_path(message)
  #
  # Static usage for legend/help dialog (renders a non-clickable span):
  #   keycap key: "R", label: "reply", static: true
  #
  # variant: :phosphor (default, dim/idle respond+state actions)
  #          :phosphor_on (lit phosphor, e.g. read toggle when unread)
  #          :amber      (warning: junk, starred)
  #          :signal     (destructive: trash, block)
  #          :moss       (safety: trust)
  def keycap(key:, label:, path: nil, method: :post, variant: :phosphor,
    confirm: nil, static: false, form_class: "inline")
    color_classes = keycap_variant_classes(variant)
    cell_classes = token_list(
      "flex h-9 w-9 items-center justify-center border font-mono text-sm uppercase transition-colors",
      color_classes[:cell]
    )
    tooltip_classes = token_list(
      "pointer-events-none absolute left-1/2 top-full z-20 mt-1.5 -translate-x-1/2 whitespace-nowrap border bg-bg px-2 py-0.5 font-mono text-[0.6rem] uppercase tracking-wider opacity-0 transition-opacity duration-150 group-hover:opacity-100 group-focus-within:opacity-100",
      color_classes[:tooltip]
    )

    tooltip = tag.span("[ #{label} ]", class: tooltip_classes)

    if static
      cell = tag.span(key.to_s.upcase, class: cell_classes, "aria-hidden": true)
      tag.div(class: "group relative") { cell + tooltip }
    else
      button_data = {shortcut: key.to_s.downcase, action_label: label}
      button_data[:turbo_confirm] = confirm if confirm.present?
      button = button_to(
        key.to_s.upcase,
        path,
        method: method,
        class: cell_classes,
        form_class: form_class,
        data: button_data,
        aria: {label: label}
      )
      tag.div(class: "group relative") { button + tooltip }
    end
  end

  # Render a small avatar-like initials tile for a sender address or name.
  def initials_tile(name_or_email, size: :md)
    initials = extract_initials(name_or_email)
    dims = case size
    when :sm
      "h-5 w-5 text-[0.55rem]"
    when :lg
      "h-20 w-20 text-lg"
    else
      "h-6 w-6 text-[0.6rem]"
    end
    tag.span(initials,
      class: "inline-flex items-center justify-center border border-hairline bg-bg-3 font-mono uppercase text-phosphor-dim #{dims}")
  end

  private

  # Variant => tailwind class strings for keycap cell + tooltip.
  # The cell idles dim and brightens on hover; the tooltip matches the
  # "brightened" color so the hover state reads as a single unit.
  def keycap_variant_classes(variant)
    {
      phosphor: {
        cell: "border-hairline text-phosphor-dim hover:border-phosphor hover:text-phosphor",
        tooltip: "border-phosphor text-phosphor"
      },
      phosphor_on: {
        cell: "border-phosphor text-phosphor hover:glow-phosphor",
        tooltip: "border-phosphor text-phosphor"
      },
      amber: {
        cell: "border-hairline text-amber hover:border-amber hover:glow-amber",
        tooltip: "border-amber text-amber"
      },
      amber_on: {
        cell: "border-amber text-amber hover:glow-amber",
        tooltip: "border-amber text-amber"
      },
      signal: {
        cell: "border-hairline text-signal hover:border-signal",
        tooltip: "border-signal text-signal"
      },
      moss: {
        cell: "border-hairline text-moss hover:border-moss",
        tooltip: "border-moss text-moss"
      },
      moss_on: {
        cell: "border-moss text-moss hover:border-moss",
        tooltip: "border-moss text-moss"
      }
    }[variant] || {
      cell: "border-hairline text-phosphor-dim hover:border-phosphor hover:text-phosphor",
      tooltip: "border-phosphor text-phosphor"
    }
  end

  def extract_initials(source)
    return "??" if source.blank?
    source = source.to_s
    token = source.include?("@") ? source.split("@").first : source
    parts = token.split(/[\s._-]+/).reject(&:blank?)
    if parts.size >= 2
      (parts[0][0].to_s + parts[1][0].to_s).upcase
    else
      parts[0].to_s[0, 2].upcase
    end
  end
end
