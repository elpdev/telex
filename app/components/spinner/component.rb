# frozen_string_literal: true

class Spinner::Component < ViewComponent::Base
  attr_reader :style, :size

  STYLE_MAP = {
    primary: "text-phosphor",
    danger: "text-signal",
    success: "text-moss",
    warning: "text-amber"
  }.freeze

  SIZE_MAP = {
    small: "text-xs",
    default: "text-sm",
    large: "text-lg"
  }.freeze

  # @param style [Symbol] :primary, :danger, :success, :warning
  # @param size [Symbol] :small, :default, :large
  def initialize(style: :primary, size: :default)
    @style = style
    @size = size
  end

  def spinner_classes
    token_list(
      "inline-block font-mono select-none",
      STYLE_MAP[style] || STYLE_MAP[:primary],
      SIZE_MAP[size] || SIZE_MAP[:default]
    )
  end
end
