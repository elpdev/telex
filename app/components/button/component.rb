# frozen_string_literal: true

class Button::Component < ViewComponent::Base
  attr_reader :tag_type, :label, :modifiers, :html_attributes

  TAG_TYPE_MAP = {
    navigation: :a,
    action: :button
  }.freeze

  STYLE_MAP = {
    primary: "rounded bg-indigo-600 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
    secondary: "rounded bg-white text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
    danger: "rounded bg-red-600 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600",
    warning: "rounded bg-yellow-600 text-sm font-semibold text-white shadow-sm hover:bg-yellow-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-yellow-600",
    link: "rounded bg-transparent text-sm font-semibold text-indigo-600 hover:text-indigo-500 cursor-pointer"
  }.freeze

  SIZE_MAP = {
    default: "px-4 py-2",
    small: "px-3 py-2",
    extra_small: "px-2 py-1"
  }.freeze

  # @param style [Symbol] :primary, :secondary, :danger, :warning, :link
  # @param behavior [Symbol] :action (button) or :navigation (link)
  # @param label [String] Button text
  # @param link_url [String] URL for navigation behavior
  # @param disabled [Boolean]
  # @param full_width [Boolean]
  # @param size [Symbol] :default, :small, :extra_small
  # @param new_tab [Boolean] Open link in new tab
  # @param extra_classes [String] Additional CSS classes
  # @param extra_attributes [Hash] Additional HTML attributes
  # @param turbo_frame [String] Turbo Frame target
  # @param turbo_action [String] Turbo Action
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
    turbo_action: nil
  )
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
      STYLE_MAP[style],
      SIZE_MAP[size],
      {"w-full": full_width},
      {disabled: disabled},
      extra_classes
    ]
  end
end
