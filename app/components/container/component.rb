# frozen_string_literal: true

class Container::Component < ViewComponent::Base
  attr_reader :modifiers

  PADDING_MAP = {
    none: "p-0",
    default: "p-6",
    large: "p-10"
  }.freeze

  # @param border [Boolean] Whether to include a border
  # @param padding [Symbol] :none, :default, :large
  # @param shadow [Boolean] ignored; retained for API compatibility
  # @param extra_classes [String] Additional CSS classes
  def initialize(border: true, padding: :default, shadow: true, extra_classes: nil)
    @modifiers = [
      "bg-bg-2 text-phosphor w-full mx-auto",
      {"border border-hairline": border},
      PADDING_MAP[padding] || PADDING_MAP[:default],
      extra_classes
    ]
  end
end
