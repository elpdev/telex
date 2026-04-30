class Contacts::ImportResult
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
end
