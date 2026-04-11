# frozen_string_literal: true

class Logo::Component < ViewComponent::Base
  # Size classes applied to the <img> tag. The logo.webp is a square
  # with generous padding around the wordmark, so these heights are
  # chosen to land the visible wordmark at roughly the intended size.
  SIZE_MAP = {
    xs: "h-8",   # rail / tight nav
    sm: "h-12",  # landing nav, inline brand mark
    md: "h-16",  # auth card header
    lg: "h-24",  # landing hero
    xl: "h-32"   # oversize splash
  }.freeze

  # @param size [Symbol] :xs, :sm, :md, :lg, :xl
  # @param variant [Symbol] :image (default, uses logo.webp) or :glyph
  #   (compact `[<>]` text, for tiny spots where the wordmark wouldn't fit)
  def initialize(size: :md, variant: :image)
    @size = size
    @variant = variant
  end

  def image?
    @variant == :image
  end

  def size_class
    SIZE_MAP[@size] || SIZE_MAP[:md]
  end
end
