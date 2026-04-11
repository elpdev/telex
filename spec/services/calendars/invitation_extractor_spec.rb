require "rails_helper"

RSpec.describe Calendars::InvitationExtractor do
  it "extracts event details and attendees from an inbound calendar invite" do
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(
      build_calendar_invitation_email(attendee_email: "leo@example.com")
    )
    message = create(:message, inbound_email: inbound_email, to_addresses: ["inbox@example.com"])

    result = described_class.call(message: message)

    expect(result).to be_present
    expect(result.uid).to eq("invite-1")
    expect(result.ical_method).to eq("REQUEST")
    expect(result.event_attributes[:title]).to eq("Launch Review")
    expect(result.attendees.map { |attendee| attendee[:email] }).to include("leo@example.com")
  end
end
