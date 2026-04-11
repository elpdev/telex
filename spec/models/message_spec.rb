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
end
