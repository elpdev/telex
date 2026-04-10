# frozen_string_literal: true

class Badge::Component < ViewComponent::Base
  attr_reader :text, :variant, :size, :extra_classes

  VARIANT_MAP = {
    default: "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300",
    primary: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300",
    success: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300",
    warning: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300",
    danger: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300",
    info: "bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-300"
  }.freeze

  SIZE_MAP = {
    small: "text-xs py-0.5 px-2",
    medium: "text-sm py-0.5 px-2.5",
    large: "text-base py-1 px-3"
  }.freeze

  # @param text [String] Badge text
  # @param variant [Symbol] :default, :primary, :success, :warning, :danger, :info
  # @param size [Symbol] :small, :medium, :large
  # @param extra_classes [String] Additional CSS classes
  def initialize(text:, variant: :default, size: :medium, extra_classes: nil)
    @text = text
    @variant = variant
    @size = size
    @extra_classes = extra_classes
  end

  def badge_classes
    token_list(
      "font-medium rounded-full inline-flex items-center",
      VARIANT_MAP[variant],
      SIZE_MAP[size],
      extra_classes
    )
  end
end
