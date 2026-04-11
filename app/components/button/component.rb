# frozen_string_literal: true

class Button::Component < ViewComponent::Base
  attr_reader :tag_type, :label, :modifiers, :html_attributes

  TAG_TYPE_MAP = {
    navigation: :a,
    action: :button
  }.freeze

  # Terminal button variants: phosphor border + label wrapped in brackets.
  # The template adds the [ LABEL ] decoration; STYLE_MAP only controls color.
  STYLE_MAP = {
    primary: "border border-phosphor text-phosphor hover:glow-phosphor hover:border-amber hover:text-amber",
    secondary: "border border-hairline text-phosphor-dim hover:border-phosphor hover:text-phosphor",
    danger: "border border-signal text-signal hover:glow-amber hover:bg-signal hover:text-bg",
    warning: "border border-amber text-amber hover:glow-amber",
    link: "border-0 text-cyan hover:text-amber underline-offset-2 hover:underline"
  }.freeze

  SIZE_MAP = {
    default: "px-4 py-2 text-xs",
    small: "px-3 py-1.5 text-xs",
    extra_small: "px-2 py-1 text-[0.65rem]"
  }.freeze

  def initialize(
    style:,
    behavior: :action,
    disabled: false,
    full_width: false,
    extra_classes: nil,
    extra_attributes: {},
    label: nil,
    link_url: nil,
    new_tab: false,
    size: :default,
    turbo_frame: nil,
    turbo_action: nil,
    bracketed: false
  )
    @bracketed = bracketed
    @link_url = link_url
    @style = style
    @tag_type = TAG_TYPE_MAP[behavior]
    @label = label

    @html_attributes = build_html_attributes(
      link_url: link_url,
      new_tab: new_tab,
      disabled: disabled,
      extra_attributes: extra_attributes,
      turbo_frame: turbo_frame,
      turbo_action: turbo_action
    )

    @modifiers = build_modifiers(
      style: style,
      size: size,
      full_width: full_width,
      extra_classes: extra_classes,
      disabled: disabled && tag_type == :a
    )
  end

  def render?
    return false unless @style.present? && tag_type.present? && label.present?
    return true if tag_type == :button
    @link_url.present? && @link_url != "#"
  end

  def display_label
    @bracketed ? "[ #{label.to_s.upcase} ]" : label.to_s
  end

  private

  def build_html_attributes(link_url:, new_tab:, disabled:, extra_attributes:, turbo_frame:, turbo_action:)
    link_disabled = disabled && tag_type == :a

    extra_attributes.deep_merge(
      href: link_url,
      disabled: disabled && !link_disabled,
      aria: {disabled: link_disabled || nil},
      tabindex: link_disabled ? "-1" : nil,
      target: new_tab ? "_blank" : nil,
      rel: new_tab ? "noopener noreferrer" : nil,
      data: {turbo_frame: turbo_frame, turbo_action: turbo_action}
    )
  end

  def build_modifiers(style:, size:, full_width:, extra_classes:, disabled:)
    [
      "inline-flex items-center justify-center font-mono uppercase tracking-wider transition-colors duration-150 cursor-pointer",
      STYLE_MAP[style],
      SIZE_MAP[size],
      {"w-full": full_width},
      {"pointer-events-none opacity-40": disabled},
      extra_classes
    ]
  end
end
