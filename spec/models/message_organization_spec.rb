require "rails_helper"

RSpec.describe MessageOrganization, type: :model do
  it "defaults to inbox" do
    organization = create(:message_organization)

    expect(organization.system_state).to eq("inbox")
  end
end
