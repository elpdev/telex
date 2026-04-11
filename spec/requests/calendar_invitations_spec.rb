require "rails_helper"

RSpec.describe "Calendar invitations", type: :request do
  it "shows linked invitation emails on the event detail page" do
    user = create(:user, email_address: "leo@example.com")
    login_user(user)
    inbox = create(:inbox, local_part: "inbox")
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(
      build_calendar_invitation_email(to: inbox.address, attendee_email: user.email_address)
    )
    message = Inbound::Ingestor.ingest!(inbound_email, inbox: inbox)
    ProcessMessageJob.perform_now(message)
    event = Calendars::InvitationSync.call(message: message, user: user)

    get calendars_event_path(event)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("invitation emails")
    expect(response.body).to include(message.subject)
  end
end
