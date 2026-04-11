module CalendarInvitationMailHelper
  def build_calendar_invitation_email(
    to: "inbox@example.com",
    attendee_email: "leo@example.com",
    uid: "invite-1",
    method: "REQUEST",
    sequence: 0,
    summary: "Launch Review",
    location: "War Room",
    status: "CONFIRMED"
  )
    calendar_lines = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Telex Specs//EN",
      "METHOD:#{method}",
      "BEGIN:VEVENT",
      "UID:#{uid}",
      "SEQUENCE:#{sequence}",
      "SUMMARY:#{summary}",
      "DESCRIPTION:Agenda review",
      "LOCATION:#{location}",
      "DTSTART:20260415T100000Z",
      "DTEND:20260415T110000Z"
    ]
    calendar_lines << "STATUS:#{status}" if status.present?
    calendar_lines.concat([
      "ORGANIZER;CN=Casey:mailto:casey@example.com",
      "ATTENDEE;CN=Leo;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT;RSVP=TRUE:mailto:#{attendee_email}",
      "END:VEVENT",
      "END:VCALENDAR"
    ])
    calendar_body = calendar_lines.join("\n")

    mail = Mail.new
    mail.from = "casey@example.com"
    mail.to = to
    mail.subject = summary
    mail.message_id = "<#{uid}-#{sequence}@example.com>"
    mail.date = Time.zone.parse("2026-04-10 10:00:00 UTC")
    mail.mime_version = "1.0"

    mail.text_part = Mail::Part.new do
      content_type "text/plain; charset=UTF-8"
      body "Please review this invitation."
    end

    mail.add_part(Mail::Part.new do
      content_type "text/calendar; method=#{method}; charset=UTF-8"
      body calendar_body
    end)

    mail.to_s
  end
end

RSpec.configure do |config|
  config.include CalendarInvitationMailHelper
end
