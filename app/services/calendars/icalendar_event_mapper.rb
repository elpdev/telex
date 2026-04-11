class Calendars::IcalendarEventMapper
  def self.call(event:, fallback_time_zone:, source: :ics_import)
    new(event:, fallback_time_zone:, source:).call
  end

  def initialize(event:, fallback_time_zone:, source:)
    @event = event
    @fallback_time_zone = fallback_time_zone.presence || Time.zone.tzinfo.name
    @source = source
  end

  def call
    starts_at = convert_time(event.dtstart)
    return if starts_at.blank?

    {
      event_attributes: {
        title: event.summary.to_s.presence || "Untitled event",
        description: event.description.to_s.presence,
        location: event.location.to_s.presence,
        starts_at: starts_at,
        ends_at: convert_end_time(event.dtend, all_day_event?, starts_at),
        all_day: all_day_event?,
        time_zone: time_zone_for(event),
        status: normalized_status(event.status),
        organizer_name: Array(event.organizer&.ical_params&.[]("cn")).first,
        organizer_email: event.organizer.to_s.delete_prefix("mailto:").presence,
        source: source,
        uid: event.uid.to_s.presence,
        raw_payload: event.to_ical,
        recurrence_rule: Array(event.rrule).first&.value_ical.to_s.presence,
        recurrence_exceptions: Array(event.exdate).flat_map { |value| Array(value).map { |entry| convert_time(entry)&.utc&.iso8601 } }.compact,
        sequence_number: event.sequence.to_i,
        last_imported_at: Time.current
      },
      attendees: attendee_attributes,
      uid: event.uid.to_s.presence,
      sequence_number: event.sequence.to_i
    }
  end

  private

  attr_reader :event, :fallback_time_zone, :source

  def attendee_attributes
    Array(event.attendee).filter_map do |attendee|
      email = attendee.to_s.delete_prefix("mailto:").presence
      next if email.blank?

      {
        email: email,
        name: Array(attendee.ical_params["cn"]).first,
        role: normalized_role(Array(attendee.ical_params["role"]).first),
        participation_status: normalized_participation_status(Array(attendee.ical_params["partstat"]).first),
        response_requested: ActiveModel::Type::Boolean.new.cast(Array(attendee.ical_params["rsvp"]).first)
      }
    end
  end

  def convert_time(value)
    raw = value&.to_time
    return if raw.blank?

    raw.in_time_zone(time_zone_for_value(value))
  end

  def convert_end_time(value, all_day, starts_at)
    return starts_at.end_of_day if all_day && value.blank?
    return starts_at + 1.hour if value.blank?

    converted = convert_time(value)
    return converted unless all_day

    (converted - 1.second).end_of_day
  end

  def all_day_event?
    event.dtstart.is_a?(Date) || event.dtstart&.value.is_a?(Date)
  end

  def time_zone_for(event)
    time_zone_for_value(event.dtstart) || fallback_time_zone
  end

  def time_zone_for_value(value)
    Array(value&.ical_params&.[]("tzid")).first.presence || fallback_time_zone
  end

  def normalized_status(status)
    normalized = status.to_s.downcase
    return :tentative if normalized == "tentative"
    return :cancelled if normalized == "cancelled"

    :confirmed
  end

  def normalized_role(role)
    case role.to_s.upcase
    when "OPT-PARTICIPANT"
      :optional
    when "CHAIR"
      :chair
    when "NON-PARTICIPANT"
      :non_participant
    else
      :required
    end
  end

  def normalized_participation_status(status)
    case status.to_s.upcase
    when "ACCEPTED"
      :accepted
    when "TENTATIVE"
      :tentative
    when "DECLINED"
      :declined
    else
      :needs_action
    end
  end
end
