# frozen_string_literal: true

class Badge::Component < ViewComponent::Base
  attr_reader :text, :variant, :size, :extra_classes

  VARIANT_MAP = {
    default: "border-phosphor-faint text-phosphor-dim",
    primary: "border-phosphor text-phosphor",
    success: "border-moss text-moss",
    warning: "border-amber text-amber",
    danger: "border-signal text-signal",
    info: "border-cyan text-cyan",
    amber: "border-amber text-amber",
    phosphor: "border-phosphor text-phosphor",
    cyan: "border-cyan text-cyan",
    signal: "border-signal text-signal",
    dim: "border-hairline text-phosphor-faint"
  }.freeze

  SIZE_MAP = {
    small: "text-[0.6rem] py-[1px] px-1.5",
    medium: "text-[0.65rem] py-0.5 px-2",
    large: "text-xs py-1 px-2.5"
  }.freeze

  # @param text [String] Badge text
  # @param variant [Symbol] Color variant
  # @param size [Symbol] :small, :medium, :large
  # @param bracketed [Boolean] Wrap text in brackets like [VALUE]
  # @param uppercase [Boolean] Force uppercase (default false to preserve
  #   original casing for call sites from before the terminal redesign)
  def initialize(text:, variant: :default, size: :medium, extra_classes: nil, bracketed: false, uppercase: false)
    @text = text
    @variant = variant
    @size = size
    @extra_classes = extra_classes
    @bracketed = bracketed
    @uppercase = uppercase
  end

  def display_text
    value = @uppercase ? text.to_s.upcase : text.to_s
    @bracketed ? "[#{value}]" : value
  end

  def badge_classes
    token_list(
      "inline-flex items-center border font-mono tracking-wider whitespace-nowrap",
      {uppercase: @uppercase},
      VARIANT_MAP[variant] || VARIANT_MAP[:default],
      SIZE_MAP[size] || SIZE_MAP[:medium],
      extra_classes
    )
  end
end
