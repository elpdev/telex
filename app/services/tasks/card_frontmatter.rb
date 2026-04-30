module Tasks
  class CardFrontmatter
    Result = Struct.new(:frontmatter, :body, :present?, keyword_init: true)

    SUPPORTED_FIELDS = %w[title column].freeze

    def self.parse(document)
      new(document).parse
    end

    def initialize(document)
      @document = document.to_s
    end

    def parse
      match = document.match(/\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\z)/m)
      return Result.new(frontmatter: {}, body: document, present?: false) unless match

      frontmatter = YAML.safe_load(match[1], aliases: false) || {}
      frontmatter = {} unless frontmatter.is_a?(Hash)

      Result.new(frontmatter: frontmatter.stringify_keys.slice(*SUPPORTED_FIELDS), body: document[match[0].length..].to_s, present?: true)
    end

    private

    attr_reader :document
  end
end
