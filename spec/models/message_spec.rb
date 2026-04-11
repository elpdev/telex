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

  it "defaults to inbox state for users without organization records" do
    user = create(:user)
    message = create(:message)

    expect(message.effective_system_state_for(user)).to eq("inbox")
  end

  it "assigns user labels through the organization record" do
    user = create(:user)
    message = create(:message)
    label = create(:label, user: user, name: "Billing")

    message.assign_labels_for(user, [label.id])

    expect(message.labels_for(user).map(&:name)).to eq(["Billing"])
  end

  it "tracks read and starred state per user" do
    user = create(:user)
    message = create(:message)

    expect(message.read_for?(user)).to eq(false)
    expect(message.unread_for?(user)).to eq(true)
    expect(message.starred_for?(user)).to eq(false)
    expect(message.read_at_for(user)).to be_nil

    message.mark_read_for(user)
    expect(message.read_for?(user)).to eq(true)
    expect(message.read_at_for(user)).to be_present

    message.mark_unread_for(user)
    expect(message.read_for?(user)).to eq(false)

    message.set_starred_for(user, true)
    expect(message.starred_for?(user)).to eq(true)

    message.set_starred_for(user, false)
    expect(message.starred_for?(user)).to eq(false)
  end
end
