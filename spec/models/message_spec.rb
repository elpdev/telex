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

  it "refreshes the search index when attachments change" do
    message = create(:message, subject: "Quarterly report")

    message.attachments.attach(
      io: StringIO.new("file contents"),
      filename: "report.pdf",
      content_type: "application/pdf"
    )

    expect(message.reload.search_text).to include("report.pdf")
  end

  it "filters messages by free text, recipient, and date range" do
    older_message = create(
      :message,
      subject: "Old update",
      from_address: "older@example.com",
      to_addresses: ["team@example.com"],
      received_at: Time.zone.parse("2026-04-01 10:00:00")
    )
    matching_message = create(
      :message,
      subject: "Launch plan",
      from_name: "Alice Sender",
      from_address: "alice@example.com",
      to_addresses: ["product@example.com"],
      cc_addresses: ["team@example.com"],
      text_body: "Launch checklist attached",
      received_at: Time.zone.parse("2026-04-10 10:00:00")
    )

    filtered = described_class.apply_search_filters(Message.all, {
      query: "launch",
      recipient: "team@example.com",
      sender: "alice",
      received_from: "2026-04-09",
      received_to: "2026-04-10"
    })

    expect(filtered).to contain_exactly(matching_message)
    expect(filtered).not_to include(older_message)
  end

  it "defines the processing statuses" do
    expect(described_class.statuses.keys).to eq(%w[received processing processed failed])
  end
end
