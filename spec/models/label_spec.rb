require "rails_helper"

RSpec.describe Label, type: :model do
  it "requires a unique name per user" do
    user = create(:user)
    create(:label, user: user, name: "Billing")

    label = build(:label, user: user, name: "Billing")

    expect(label).not_to be_valid
  end
end
