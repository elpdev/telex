require "rails_helper"

RSpec.describe ConversationOrganization, type: :model do
  it "defaults to inbox" do
    organization = create(:conversation_organization)

    expect(organization.system_state).to eq("inbox")
  end
end
