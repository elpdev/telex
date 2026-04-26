require "rails_helper"

RSpec.describe Tasks::BoardWriter do
  it "writes columns while preserving title content before the first column" do
    markdown = described_class.new("# Website\n\nSome context.\n").write(
      "Todo" => ["cards/homepage-copy.md"],
      "Done" => []
    )

    expect(markdown).to eq(<<~MARKDOWN)
      # Website

      Some context.

      ## Todo
      - [[cards/homepage-copy.md]]

      ## Done
    MARKDOWN
  end

  it "builds a default board" do
    markdown = described_class.default_markdown("Launch")

    expect(markdown).to include("# Launch")
    expect(markdown).to include("## Todo")
    expect(markdown).to include("## Doing")
    expect(markdown).to include("## Done")
  end
end
