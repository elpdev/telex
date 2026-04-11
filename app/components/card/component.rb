# frozen_string_literal: true

class Card::Component < ViewComponent::Base
  renders_one :footer_content

  attr_reader :title, :subtitle, :footer, :border, :padding, :extra_classes

  PADDING_MAP = {
    none: "",
    sm: "p-3",
    md: "p-5",
    lg: "p-7"
  }.freeze

  # Terminal-style frame. No rounded, no shadow. Uses 1px hairline border
  # and an optional uppercased title that appears as a bracket-labeled tab.
  def initialize(
    title: nil,
    subtitle: nil,
    footer: false,
    border: true,
    padding: :md,
    extra_classes: nil,
    # accepted and ignored (legacy API) so existing call sites don't break
    shadow: nil,
    rounded: nil
  )
    @title = title
    @subtitle = subtitle
    @footer = footer
    @border = border
    @padding = padding
    @extra_classes = extra_classes
  end

  def card_classes
    token_list(
      "relative flex w-full flex-col bg-bg-2 text-phosphor",
      {"border border-hairline": border},
      extra_classes
    )
  end

  def body_classes
    PADDING_MAP[padding] || PADDING_MAP[:md]
  end

  def has_header?
    title.present? || subtitle.present?
  end

  def bracketed_title
    "[ #{title.to_s.upcase} ]"
  end
end
