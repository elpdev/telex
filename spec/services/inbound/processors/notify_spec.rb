require "rails_helper"

RSpec.describe Inbound::Processors::Notify do
  it "delivers a noticed event to the configured admin" do
    admin = create(:user, :admin)
    message = create(:message)
    inbox = message.inbox
    inbox.update!(pipeline_overrides: {"notify_user_id" => admin.id})
    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: inbox,
      message: message,
      subaddress: nil,
      metadata: {}
    )

    expect {
      described_class.call(context)
    }.to change(Noticed::Event, :count).by(1)
      .and change(Noticed::Notification, :count).by(1)

    expect(admin.notifications.last.event).to be_a(Inbound::MessageReceivedNotifier)
  end
end
