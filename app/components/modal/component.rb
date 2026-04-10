# frozen_string_literal: true

class Modal::Component < ViewComponent::Base
  renders_one :trigger
  renders_one :footer_content

  attr_reader :title, :size, :dismissible

  SIZE_MAP = {
    sm: "max-w-sm",
    md: "max-w-md",
    lg: "max-w-lg",
    xl: "max-w-xl",
    full: "max-w-4xl"
  }.freeze

  # @param title [String, nil] Modal header title
  # @param size [Symbol] :sm, :md, :lg, :xl, :full
  # @param dismissible [Boolean] Whether clicking the backdrop closes the modal
  def initialize(title: nil, size: :md, dismissible: true)
    @title = title
    @size = size
    @dismissible = dismissible
  end

  def dialog_classes
    token_list(
      "w-full rounded-lg shadow-xl backdrop:bg-black/50 p-0",
      "bg-white dark:bg-gray-800",
      SIZE_MAP[size]
    )
  end

  def backdrop_action
    "mousedown->modal#backdropClick" if dismissible
  end
end
