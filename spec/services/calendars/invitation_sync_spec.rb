require "rails_helper"

RSpec.describe Calendars::InvitationSync do
  it "creates a local calendar event, attendees, and a message link" do
    user = create(:user, email_address: "leo@example.com")
    inbox = create(:inbox, local_part: "inbox")
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(
      build_calendar_invitation_email(to: inbox.address, attendee_email: user.email_address)
    )
    message = create(:message, inbox: inbox, inbound_email: inbound_email, to_addresses: [inbox.address])

    event = described_class.call(message: message, user: user)

    expect(event).to be_persisted
    expect(event.calendar.user).to eq(user)
    expect(event.uid).to eq("invite-1")
    expect(event).to be_email_invitation
    expect(event.calendar_event_attendees.find_by(email: user.email_address)).to be_present
    expect(event.calendar_event_links.find_by(message: message)).to be_present
  end

  it "does not overwrite a newer event version with an older sequence" do
    user = create(:user, email_address: "leo@example.com")
    inbox = create(:inbox, local_part: "inbox")
    event = create(
      :calendar_event,
      calendar: user.calendars.first,
      uid: "invite-1",
      title: "New title",
      source: :email_invitation,
      sequence_number: 2
    )

    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(
      build_calendar_invitation_email(to: inbox.address, attendee_email: user.email_address, sequence: 1, summary: "Old title")
    )
    message = create(:message, inbox: inbox, inbound_email: inbound_email, to_addresses: [inbox.address])

    described_class.call(message: message, user: user)

    expect(event.reload.title).to eq("New title")
    expect(event.calendar_event_links.find_by(message: message)).to be_present
  end

  it "marks the event cancelled when the invite method is CANCEL without a status" do
    user = create(:user, email_address: "leo@example.com")
    inbox = create(:inbox, local_part: "inbox")
    event = create(
      :calendar_event,
      calendar: user.calendars.first,
      uid: "invite-1",
      title: "Launch Review",
      status: :confirmed,
      source: :email_invitation,
      sequence_number: 0
    )

    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(
      build_calendar_invitation_email(
        to: inbox.address,
        attendee_email: user.email_address,
        method: "CANCEL",
        sequence: 1,
        status: nil
      )
    )
    message = create(:message, inbox: inbox, inbound_email: inbound_email, to_addresses: [inbox.address])

    described_class.call(message: message, user: user)

    expect(event.reload).to be_cancelled
    expect(event.sequence_number).to eq(1)
    expect(event.calendar_event_links.find_by(message: message)&.ical_method).to eq("CANCEL")
  end
end
