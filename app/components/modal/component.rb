# frozen_string_literal: true

class Modal::Component < ViewComponent::Base
  renders_one :trigger
  renders_one :footer_content

  attr_reader :title, :size, :dismissible

  SIZE_MAP = {
    sm: "max-w-sm",
    md: "max-w-md",
    lg: "max-w-xl",
    xl: "max-w-2xl",
    full: "max-w-4xl"
  }.freeze

  def initialize(title: nil, size: :md, dismissible: true)
    @title = title
    @size = size
    @dismissible = dismissible
  end

  def dialog_classes
    token_list(
      "w-full border border-phosphor bg-bg text-phosphor p-0 backdrop:bg-bg/80 backdrop:backdrop-blur-sm glow-box-phosphor",
      SIZE_MAP[size] || SIZE_MAP[:md]
    )
  end

  def backdrop_action
    "mousedown->modal#backdropClick" if dismissible
  end

  def bracketed_title
    return nil if title.blank?
    "[ #{title.to_s.upcase} ]"
  end
end
