require "rails_helper"

RSpec.describe Message, type: :model do
  it "supports rich text bodies" do
    message = create(:message)
    message.body = "<div>Hello</div>"
    message.save!

    expect(message.body.to_plain_text).to eq("Hello")
  end

  it "supports attachments" do
    message = create(:message)
    message.attachments.attach(
      io: StringIO.new("file contents"),
      filename: "note.txt",
      content_type: "text/plain"
    )

    expect(message.attachments).to be_attached
  end

  it "defines the processing statuses" do
    expect(described_class.statuses.keys).to eq(%w[received processing processed failed])
  end
end
