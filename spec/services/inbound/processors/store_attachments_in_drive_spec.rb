require "rails_helper"

RSpec.describe Inbound::Processors::StoreAttachmentsInDrive do
  it "creates stored files for attachments in the inbox folder" do
    user = create(:user)
    folder = create(:folder, user: user)
    domain = create(:domain, user: user)
    inbox = create(:inbox, domain: domain, folder: folder)
    message = create(:message, inbox: inbox)
    message.attachments.attach(io: StringIO.new("data"), filename: "file.txt", content_type: "text/plain")

    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: inbox,
      message: message,
      subaddress: nil,
      metadata: {}
    )

    expect {
      described_class.call(context)
    }.to change { StoredFile.count }.by(1)

    stored_file = StoredFile.last
    expect(stored_file.folder).to eq(folder)
    expect(stored_file.user).to eq(user)
    expect(stored_file.filename).to eq("file.txt")
    expect(stored_file.source).to eq("message_attachment")
  end

  it "falls back to the domain folder when the inbox has none" do
    user = create(:user)
    folder = create(:folder, user: user)
    domain = create(:domain, user: user, folder: folder)
    inbox = create(:inbox, domain: domain, folder: nil)
    message = create(:message, inbox: inbox)
    message.attachments.attach(io: StringIO.new("data"), filename: "file.txt", content_type: "text/plain")

    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: inbox,
      message: message,
      subaddress: nil,
      metadata: {}
    )

    expect {
      described_class.call(context)
    }.to change { StoredFile.count }.by(1)

    expect(StoredFile.last.folder).to eq(folder)
  end

  it "does nothing when no folder is mapped" do
    domain = create(:domain, folder: nil)
    inbox = create(:inbox, domain: domain, folder: nil)
    message = create(:message, inbox: inbox)
    message.attachments.attach(io: StringIO.new("data"), filename: "file.txt", content_type: "text/plain")

    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: inbox,
      message: message,
      subaddress: nil,
      metadata: {}
    )

    expect {
      described_class.call(context)
    }.not_to change { StoredFile.count }
  end

  it "does nothing when the message has no attachments" do
    user = create(:user)
    folder = create(:folder, user: user)
    domain = create(:domain, user: user, folder: folder)
    inbox = create(:inbox, domain: domain, folder: folder)
    message = create(:message, inbox: inbox)

    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: inbox,
      message: message,
      subaddress: nil,
      metadata: {}
    )

    expect {
      described_class.call(context)
    }.not_to change { StoredFile.count }
  end

  it "ignores duplicate stored files for the same blob" do
    user = create(:user)
    folder = create(:folder, user: user)
    domain = create(:domain, user: user)
    inbox = create(:inbox, domain: domain, folder: folder)
    message = create(:message, inbox: inbox)
    message.attachments.attach(io: StringIO.new("data"), filename: "file.txt", content_type: "text/plain")

    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: inbox,
      message: message,
      subaddress: nil,
      metadata: {}
    )

    described_class.call(context)

    expect {
      described_class.call(context)
    }.not_to change { StoredFile.count }
  end
end
