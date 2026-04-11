class Calendars::RecurrenceRuleBuilder
  def self.call(parsed_attributes, raw_params)
    frequency = raw_params["recurrence_frequency"].to_s.presence
    return if frequency.blank? || frequency == "none"

    interval = raw_params["recurrence_interval"].to_i
    interval = 1 if interval <= 0

    parts = ["FREQ=#{frequency.upcase}", "INTERVAL=#{interval}"]

    if frequency == "weekly"
      weekdays = Array(raw_params["recurrence_weekdays"]).reject(&:blank?)
      weekdays = [weekday_code(parsed_attributes.fetch(:starts_at).wday)] if weekdays.empty?
      parts << "BYDAY=#{weekdays.join(",")}"
    elsif frequency == "monthly"
      parts << "BYMONTHDAY=#{parsed_attributes.fetch(:starts_at).day}"
    end

    if raw_params["recurrence_until"].present?
      until_time = Time.zone.parse(raw_params["recurrence_until"]).end_of_day.utc.strftime("%Y%m%dT%H%M%SZ")
      parts << "UNTIL=#{until_time}"
    end

    parts.join(";")
  end

  def self.weekday_code(wday)
    %w[SU MO TU WE TH FR SA].fetch(wday)
  end

  private_class_method :weekday_code
end
