# frozen_string_literal: true

class Card::Component < ViewComponent::Base
  renders_one :footer_content

  attr_reader :title, :subtitle, :footer, :border, :shadow, :padding, :rounded, :extra_classes

  SHADOW_MAP = {
    none: "",
    sm: "shadow-sm",
    md: "shadow",
    lg: "shadow-lg",
    xl: "shadow-xl"
  }.freeze

  ROUNDED_MAP = {
    none: "",
    sm: "rounded-sm",
    md: "rounded",
    lg: "rounded-lg",
    full: "rounded-full"
  }.freeze

  PADDING_MAP = {
    none: "",
    sm: "p-2",
    md: "p-4",
    lg: "p-6"
  }.freeze

  # @param title [String, nil] Card title text
  # @param subtitle [String, nil] Card subtitle text
  # @param footer [Boolean] Whether to include a footer section
  # @param border [Boolean] Whether to include a border
  # @param shadow [Symbol] :none, :sm, :md, :lg, :xl
  # @param padding [Symbol] :none, :sm, :md, :lg
  # @param rounded [Symbol] :none, :sm, :md, :lg, :full
  # @param extra_classes [String] Additional CSS classes
  def initialize(
    title: nil,
    subtitle: nil,
    footer: false,
    border: true,
    shadow: :md,
    padding: :md,
    rounded: :md,
    extra_classes: nil
  )
    @title = title
    @subtitle = subtitle
    @footer = footer
    @border = border
    @shadow = shadow
    @padding = padding
    @rounded = rounded
    @extra_classes = extra_classes
  end

  def card_classes
    token_list(
      "flex flex-col bg-white dark:bg-gray-800 w-full",
      {"border border-gray-200 dark:border-gray-700": border},
      SHADOW_MAP[shadow],
      ROUNDED_MAP[rounded],
      extra_classes
    )
  end

  def body_classes
    PADDING_MAP[padding]
  end

  def has_header?
    title.present? || subtitle.present?
  end
end
