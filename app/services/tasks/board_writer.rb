module Tasks
  class BoardWriter
    DEFAULT_COLUMNS = ["Todo", "Doing", "Done"]

    def self.default_markdown(title)
      new("# #{title.to_s.strip.presence || "Board"}\n").write(DEFAULT_COLUMNS.index_with { [] })
    end

    def initialize(markdown)
      @markdown = markdown.to_s
    end

    def write(columns)
      title_lines = markdown.lines.take_while { |line| !line.match?(/\A##\s+/) }
      title_lines = ["# Board\n", "\n"] if title_lines.join.strip.blank?

      body = columns.map do |name, paths|
        card_lines = Array(paths).map { |path| "- [[#{path}]]" }
        (["## #{name}"] + card_lines).join("\n")
      end.join("\n\n")

      "#{title_lines.join.rstrip}\n\n#{body}\n"
    end

    private

    attr_reader :markdown
  end
end
