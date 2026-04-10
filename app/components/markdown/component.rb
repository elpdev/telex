# frozen_string_literal: true

class Markdown::Component < ViewComponent::Base
  include MarkdownHelper

  attr_reader :text, :theme, :extra_classes

  # @param text [String, nil] Markdown text to render (alternative to block content)
  # @param theme [String, nil] Override syntax highlight theme (e.g., "InspiredGitHub")
  # @param extra_classes [String, nil] Additional CSS classes for the wrapper div
  def initialize(text: nil, theme: nil, extra_classes: nil)
    @text = text
    @theme = theme
    @extra_classes = extra_classes
  end

  def rendered_html
    source = text.presence || content
    return "".html_safe if source.blank?

    overrides = {}
    if theme.present?
      config = Rails.application.config.commonmarker
      overrides[:plugins] = config[:plugins].deep_merge(syntax_highlighter: {theme: theme})
      overrides[:options] = config[:options]
    end

    render_markdown(source, **overrides)
  end

  def wrapper_classes
    token_list("markdown-content prose dark:prose-invert", extra_classes)
  end
end
