# frozen_string_literal: true

class Container::Component < ViewComponent::Base
  attr_reader :modifiers

  PADDING_MAP = {
    none: "p-0",
    default: "p-8",
    large: "p-16"
  }.freeze

  # @param border [Boolean] Whether to include a border
  # @param padding [Symbol] :none, :default, :large
  # @param shadow [Boolean] Whether to include a shadow
  # @param extra_classes [String] Additional CSS classes
  def initialize(border: true, padding: :default, shadow: true, extra_classes: nil)
    @modifiers = [
      "bg-white dark:bg-gray-800 rounded-lg mx-auto w-full",
      {"border border-gray-200 dark:border-gray-700": border},
      {"shadow-sm": shadow},
      PADDING_MAP[padding],
      extra_classes
    ]
  end
end
