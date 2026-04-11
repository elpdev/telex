class Calendars::ImportResult
  attr_reader :created, :updated, :skipped, :failed, :errors

  def initialize(created:, updated:, skipped:, failed:, errors: [])
    @created = created
    @updated = updated
    @skipped = skipped
    @failed = failed
    @errors = errors
  end

  def success?
    failed.zero?
  end

  def message
    summary = [
      "created #{created}",
      "updated #{updated}",
      "skipped #{skipped}",
      "failed #{failed}"
    ].join(" :: ")

    errors.any? ? "#{summary} :: #{errors.join(" | ")}" : summary
  end
end
