module Tasks
  class Board
    Card = Struct.new(:path, :title, keyword_init: true)
    Column = Struct.new(:name, :cards, keyword_init: true)

    LINK_PATTERN = /\A\s*-\s*\[\[([^\]]+)\]\]\s*\z/

    def self.parse(markdown)
      new(markdown).parse
    end

    def initialize(markdown)
      @markdown = markdown.to_s
    end

    def parse
      columns = []
      current_column = nil

      markdown.each_line do |line|
        if (heading = line.match(/\A##\s+(.+)\s*\z/))
          current_column = Column.new(name: heading[1].strip, cards: [])
          columns << current_column
        elsif current_column && (card = line.match(LINK_PATTERN))
          path = card[1].strip
          current_column.cards << Card.new(path: path, title: title_for(path))
        end
      end

      columns
    end

    private

    attr_reader :markdown

    def title_for(path)
      File.basename(path.to_s, ".md").tr("-_", " ").squish.presence || path
    end
  end
end
