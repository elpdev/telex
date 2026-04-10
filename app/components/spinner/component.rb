# frozen_string_literal: true

class Spinner::Component < ViewComponent::Base
  attr_reader :style, :size

  STYLE_MAP = {
    primary: "text-gray-200 fill-blue-600 dark:text-gray-600",
    danger: "text-gray-200 fill-red-600 dark:text-gray-600",
    success: "text-gray-200 fill-green-600 dark:text-gray-600",
    warning: "text-gray-200 fill-yellow-600 dark:text-gray-600"
  }.freeze

  SIZE_MAP = {
    small: "w-4 h-4",
    default: "w-8 h-8",
    large: "w-12 h-12"
  }.freeze

  # @param style [Symbol] :primary, :danger, :success, :warning
  # @param size [Symbol] :small, :default, :large
  def initialize(style: :primary, size: :default)
    @style = style
    @size = size
  end

  def spinner_classes
    token_list("inline animate-spin", STYLE_MAP[style], SIZE_MAP[size])
  end
end
