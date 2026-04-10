module MarkdownHelper
  # Renders a markdown string to HTML with syntax highlighting.
  #
  #   render_markdown("# Hello **world**")
  #   # => "<h1>Hello <strong>world</strong></h1>\n"
  #
  # Options from config/initializers/commonmarker.rb are used by default.
  # Pass custom options to override:
  #
  #   render_markdown(text, plugins: { syntax_highlighter: { theme: "InspiredGitHub" } })
  #
  def render_markdown(text, **overrides)
    return "".html_safe if text.blank?

    config = Rails.application.config.commonmarker
    options = overrides[:options] || config[:options]
    plugins = overrides[:plugins] || config[:plugins]

    Commonmarker.to_html(text, options: options, plugins: plugins).html_safe
  end
end
