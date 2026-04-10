# Commonmarker configuration
# Default options for markdown rendering throughout the application.
# Used by MarkdownHelper#render_markdown.
#
# Theme options: base16-ocean.dark, InspiredGitHub, Solarized (dark), Solarized (light)
Rails.application.config.commonmarker = {
  options: {
    parse: {smart: true},
    render: {unsafe: true, escape: false},
    extension: {
      table: true,
      autolink: true,
      strikethrough: true,
      tagfilter: true,
      tasklist: true
    }
  },
  plugins: {
    syntax_highlighter: {theme: "base16-ocean.dark"}
  }
}
