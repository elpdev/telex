class Calendars::InvitationResponseUpdater
  def self.call(event:, user:, message:, participation_status:)
    new(event:, user:, message:, participation_status:).call
  end

  def initialize(event:, user:, message:, participation_status:)
    @event = event
    @user = user
    @message = message
    @participation_status = participation_status
  end

  def call
    attendee = event.attendee_for_addresses(candidate_addresses) || event.calendar_event_attendees.new(email: fallback_email)
    attendee.participation_status = participation_status
    attendee.name ||= user.name.presence
    attendee.response_requested = true if attendee.new_record?
    attendee.save!
    attendee
  end

  private

  attr_reader :event, :user, :message, :participation_status

  def candidate_addresses
    [user.email_address, message.inbox.address, *message.to_addresses]
  end

  def fallback_email
    candidate_addresses.find(&:present?) || user.email_address
  end
end
