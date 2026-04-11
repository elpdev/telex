require "rails_helper"

RSpec.describe MessageOrganization, type: :model do
  it "defaults to inbox" do
    organization = create(:message_organization)

    expect(organization.system_state).to eq("inbox")
  end

  it "defaults starred to false and read_at to nil" do
    organization = create(:message_organization)

    expect(organization.starred).to eq(false)
    expect(organization.read_at).to be_nil
  end

  it "can be marked read, unread, starred, and unstarred" do
    organization = create(:message_organization)

    organization.mark_read!
    expect(organization.read?).to eq(true)

    organization.mark_unread!
    expect(organization.read?).to eq(false)

    organization.star!
    expect(organization.starred).to eq(true)

    organization.unstar!
    expect(organization.starred).to eq(false)
  end
end
