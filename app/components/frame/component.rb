# frozen_string_literal: true

# Frame::Component renders a box-drawing terminal frame around its content,
# with an optional bracketed title embedded in the top border.
#
# Example:
#   <%= render Frame::Component.new(title: "AUTH :: SIGN IN") do %>
#     ...
#   <% end %>
#
# Output (simplified):
#   +-[ AUTH :: SIGN IN ]----------+
#   |                              |
#   |   content                    |
#   |                              |
#   +------------------------------+
class Frame::Component < ViewComponent::Base
  attr_reader :title, :variant, :padding, :extra_classes

  VARIANT_MAP = {
    phosphor: "border-phosphor text-phosphor",
    amber: "border-amber text-amber",
    cyan: "border-cyan text-cyan",
    signal: "border-signal text-signal",
    hairline: "border-hairline text-phosphor"
  }.freeze

  PADDING_MAP = {
    none: "p-0",
    sm: "p-3",
    md: "p-5",
    lg: "p-8"
  }.freeze

  def initialize(title: nil, variant: :hairline, padding: :md, extra_classes: nil)
    @title = title
    @variant = variant
    @padding = padding
    @extra_classes = extra_classes
  end

  def frame_classes
    token_list(
      "relative border bg-bg-2",
      VARIANT_MAP[variant] || VARIANT_MAP[:hairline],
      extra_classes
    )
  end

  def body_classes
    PADDING_MAP[padding] || PADDING_MAP[:md]
  end

  def bracketed_title
    "[ #{title.to_s.upcase} ]"
  end
end
