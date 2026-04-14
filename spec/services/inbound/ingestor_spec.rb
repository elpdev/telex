require "rails_helper"

RSpec.describe Inbound::Ingestor do
  let(:user) { create(:user) }
  let(:domain) { create(:domain, user: user, name: "lbp.dev") }
  let(:inbox) { create(:inbox, domain: domain, local_part: "receipts") }

  it "persists bodies, attachments, and the subaddress" do
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(Rails.root.join("spec/fixtures/files/inbound/html_with_attachment.eml").read)

    message = described_class.ingest!(inbound_email, inbox: inbox, subaddress: "amazon")

    expect(message).to be_persisted
    expect(message.subaddress).to eq("amazon")
    expect(message.conversation).to be_present
    expect(message.text_body).to include("Thanks for your purchase")
    expect(message.body.to_plain_text).to include("Thanks for your purchase")
    expect(message.attachments.map(&:filename).map(&:to_s)).to include("receipt.txt")
  end

  it "mirrors attachments into the domain drive folder by default" do
    folder = create(:folder, user: user, name: "Receipts")
    domain.update!(drive_folder: folder)
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(Rails.root.join("spec/fixtures/files/inbound/html_with_attachment.eml").read)

    expect {
      @message = described_class.ingest!(inbound_email, inbox: inbox)
    }.to change(StoredFile, :count).by(1)

    stored_file = StoredFile.order(:id).last
    expect(stored_file.folder).to eq(folder)
    expect(stored_file.user).to eq(user)
    expect(stored_file).to be_message_attachment
    expect(stored_file.blob).to eq(@message.attachments.first.blob)
    expect(stored_file.metadata).to include(
      "message_id" => @message.id,
      "inbox_id" => inbox.id,
      "domain_id" => domain.id
    )
  end

  it "prefers the inbox drive folder over the domain default" do
    domain_folder = create(:folder, user: user, name: "Domain")
    inbox_folder = create(:folder, user: user, name: "Inbox")
    domain.update!(drive_folder: domain_folder)
    inbox.update!(drive_folder: inbox_folder)
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(Rails.root.join("spec/fixtures/files/inbound/html_with_attachment.eml").read)

    described_class.ingest!(inbound_email, inbox: inbox)

    expect(StoredFile.order(:id).last.folder).to eq(inbox_folder)
  end

  it "does not create drive files when no drive folder is configured" do
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(Rails.root.join("spec/fixtures/files/inbound/html_with_attachment.eml").read)

    expect {
      described_class.ingest!(inbound_email, inbox: inbox)
    }.not_to change(StoredFile, :count)
  end

  it "is idempotent for the same inbound email" do
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(Rails.root.join("spec/fixtures/files/inbound/plain_text.eml").read)

    first = described_class.ingest!(inbound_email, inbox: inbox)
    second = described_class.ingest!(inbound_email, inbox: inbox)

    expect(first.id).to eq(second.id)
    expect(Message.count).to eq(1)
  end
end
