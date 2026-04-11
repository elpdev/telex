class Calendars::InvitationSync
  def self.call(message:, user:)
    new(message:, user:).call
  end

  def initialize(message:, user:)
    @message = message
    @user = user
  end

  def call
    return if user.blank?

    invite = Calendars::InvitationExtractor.call(message: message)
    return if invite.blank?

    calendar = user.calendars.ordered.first
    return if calendar.blank?

    event = calendar.calendar_events.find_or_initialize_by(uid: invite.uid)
    event.assign_attributes(invite.event_attributes) unless stale_sequence?(event, invite.sequence_number)
    event.save! if event.new_record? || event.changed?

    sync_attendees!(event, invite.attendees)
    sync_link!(event, invite)

    event
  end

  private

  attr_reader :message, :user

  def stale_sequence?(event, incoming_sequence)
    event.persisted? && incoming_sequence.to_i < event.sequence_number.to_i
  end

  def sync_attendees!(event, attendees)
    seen_emails = attendees.filter_map do |attributes|
      email = attributes[:email].to_s.strip.downcase.presence
      next if email.blank?

      attendee = event.calendar_event_attendees.find_or_initialize_by(email: email)
      attendee.assign_attributes(attributes)
      attendee.save! if attendee.new_record? || attendee.changed?
      email
    end

    event.calendar_event_attendees.where.not(email: seen_emails).destroy_all if seen_emails.any?
  end

  def sync_link!(event, invite)
    link = event.calendar_event_links.find_or_initialize_by(message: message)
    link.assign_attributes(
      ical_uid: invite.uid,
      ical_method: invite.ical_method,
      sequence_number: invite.sequence_number
    )
    link.save! if link.new_record? || link.changed?
  end
end
