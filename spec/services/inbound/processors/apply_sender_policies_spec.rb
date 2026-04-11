require "rails_helper"

RSpec.describe Inbound::Processors::ApplySenderPolicies do
  it "moves matching users to junk when a sender is blocked" do
    user = create(:user)
    other_user = create(:user)
    message = create(:message, from_address: "blocked@example.com")
    create(:sender_policy, user: user, target_kind: :sender, disposition: :blocked, value: "blocked@example.com")
    create(:sender_policy, user: other_user, target_kind: :sender, disposition: :trusted, value: "blocked@example.com")

    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: message.inbox,
      message: message,
      subaddress: message.subaddress,
      metadata: {}
    )

    described_class.call(context)

    expect(message.reload.effective_system_state_for(user)).to eq("junk")
    expect(message.reload.effective_system_state_for(other_user)).to eq("inbox")
    expect(context.metadata.dig("sender_policies", "blocked_user_ids")).to eq([user.id])
    expect(context.metadata.dig("sender_policies", "trusted_user_ids")).to eq([other_user.id])
  end
end
