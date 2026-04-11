class Calendars::InvitationExtractor
  Result = Struct.new(:event_attributes, :attendees, :uid, :sequence_number, :ical_method, keyword_init: true) do
    def metadata
      {
        "uid" => uid,
        "sequence_number" => sequence_number,
        "method" => ical_method,
        "title" => event_attributes[:title],
        "starts_at" => event_attributes[:starts_at]&.iso8601,
        "ends_at" => event_attributes[:ends_at]&.iso8601,
        "location" => event_attributes[:location],
        "status" => event_attributes[:status].to_s
      }.compact
    end
  end

  def self.call(message:)
    new(message:).call
  end

  def initialize(message:)
    @message = message
  end

  def call
    calendar_payloads.each do |payload|
      parsed_calendar = Icalendar::Calendar.parse(payload).find { |calendar| calendar.events.any? }
      next if parsed_calendar.blank?

      mapped = Calendars::IcalendarEventMapper.call(
        event: parsed_calendar.events.first,
        fallback_time_zone: Time.zone.tzinfo.name,
        source: :email_invitation
      )
      next if mapped.blank? || mapped[:uid].blank?

      return Result.new(
        event_attributes: mapped[:event_attributes],
        attendees: mapped[:attendees],
        uid: mapped[:uid],
        sequence_number: mapped[:sequence_number],
        ical_method: parsed_calendar.ip_method.to_s.upcase.presence || "REQUEST"
      )
    rescue Icalendar::ParseError, ArgumentError
      next
    end

    nil
  end

  private

  attr_reader :message

  def calendar_payloads
    parts = []
    mail = message.inbound_email.mail

    mail.all_parts.each do |part|
      next unless calendar_part?(part)

      decoded = part.body.decoded.to_s
      parts << decoded if decoded.present?
    end

    if parts.empty? && calendar_message?(mail)
      decoded = mail.body.decoded.to_s
      parts << decoded if decoded.present?
    end

    parts.uniq
  end

  def calendar_part?(part)
    calendar_message?(part) || part.filename.to_s.downcase.end_with?(".ics")
  end

  def calendar_message?(part)
    part.mime_type.to_s.downcase == "text/calendar"
  end
end
