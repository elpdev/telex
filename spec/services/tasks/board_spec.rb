require "rails_helper"

RSpec.describe Tasks::Board do
  it "parses kanban columns and card links from markdown" do
    columns = described_class.parse(<<~MARKDOWN)
      # Website

      ## Todo

      - [[cards/homepage-copy.md]]

      ## Doing
      - [[cards/mobile-nav.md]]
    MARKDOWN

    expect(columns.map(&:name)).to eq(["Todo", "Doing"])
    expect(columns.first.cards.first.path).to eq("cards/homepage-copy.md")
    expect(columns.first.cards.first.title).to eq("homepage copy")
    expect(columns.second.cards.first.path).to eq("cards/mobile-nav.md")
  end
end
