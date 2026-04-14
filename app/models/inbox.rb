class Inbox < ApplicationRecord
  belongs_to :domain
  belongs_to :drive_folder, class_name: "Folder", optional: true
  has_many :messages, dependent: :destroy, inverse_of: :inbox

  normalizes :local_part, with: ->(value) { value.to_s.strip.downcase }
  normalizes :address, with: ->(value) { value.to_s.strip.downcase }
  normalizes :pipeline_key, with: ->(value) { value.to_s.strip }

  validates :local_part, presence: true
  validates :address, presence: true, uniqueness: true
  validates :pipeline_key, presence: true
  validates :local_part, uniqueness: {scope: :domain_id}

  scope :active, -> { where(active: true) }

  def self.with_message_count_for(user:, count: :unread)
    case count.to_s
    when "all"
      left_joins(:messages)
        .select("inboxes.*, COUNT(messages.id) AS message_count")
        .group("inboxes.id")
    else
      unread_state = MessageOrganization.system_states.fetch("inbox")
      join_sql = Message.send(:organization_join_sql, user)
      unread_sql = sanitize_sql_array([
        <<~SQL.squish,
          SUM(CASE
            WHEN message_organizations.id IS NULL THEN 1
            WHEN message_organizations.system_state = ? AND message_organizations.read_at IS NULL THEN 1
            ELSE 0
          END) AS message_count
        SQL
        unread_state
      ])

      left_joins(:messages)
        .joins(join_sql)
        .select("inboxes.*, #{unread_sql}")
        .group("inboxes.id")
    end
  end

  before_validation :sync_address
  before_validation :coerce_json_attributes
  validate :pipeline_key_registered
  validate :pipeline_overrides_shape
  validate :forwarding_rules_shape
  validate :drive_folder_belongs_to_domain_user

  def pipeline
    Inbound::PipelineRegistry.fetch(pipeline_key)
  end

  def pipeline_overrides
    value = super
    value.is_a?(Hash) ? value : {}
  end

  def message_count
    self[:message_count] || 0
  end

  def forwarding_rules
    value = super
    value.is_a?(Array) ? value : []
  end

  def active_forwarding_rules
    normalized_forwarding_rules.select { |rule| rule["active"] }
  end

  def effective_drive_folder
    drive_folder || domain&.drive_folder
  end

  def normalized_forwarding_rules
    forwarding_rules.filter_map do |rule|
      next unless rule.is_a?(Hash)

      {
        "name" => rule["name"].to_s.strip,
        "active" => ActiveModel::Type::Boolean.new.cast(rule.fetch("active", true)),
        "from_address_pattern" => rule["from_address_pattern"].to_s.strip.downcase,
        "subject_pattern" => rule["subject_pattern"].to_s.strip.downcase,
        "subaddress_pattern" => rule["subaddress_pattern"].to_s.strip.downcase,
        "target_addresses" => Array(rule["target_addresses"]).filter_map { |address| normalize_forwarding_address(address) }.uniq
      }
    end
  end

  def matching_forwarding_rules(message)
    active_forwarding_rules.select do |rule|
      rule_matches_message?(rule, message)
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[active address created_at description domain_id drive_folder_id id local_part pipeline_key updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[domain drive_folder messages]
  end

  private

  def sync_address
    return if local_part.blank? || domain.nil? || domain.name.blank?

    self.address = "#{local_part}@#{domain.name}".downcase
  end

  def pipeline_key_registered
    return if pipeline_key.blank?
    return if Inbound::PipelineRegistry::PIPELINES.key?(pipeline_key)

    errors.add(:pipeline_key, "is not registered")
  end

  def pipeline_overrides_shape
    return if self[:pipeline_overrides].nil? || self[:pipeline_overrides].is_a?(Hash)

    errors.add(:pipeline_overrides, "must be a JSON object")
  end

  def forwarding_rules_shape
    unless self[:forwarding_rules].blank? || self[:forwarding_rules].is_a?(Array)
      errors.add(:forwarding_rules, "must be a JSON array")
      return
    end

    normalized_forwarding_rules.each_with_index do |rule, index|
      if rule["target_addresses"].blank?
        errors.add(:forwarding_rules, "rule #{index + 1} must include at least one target address")
      end

      next if rule["target_addresses"].all? { |address| address.match?(URI::MailTo::EMAIL_REGEXP) }

      errors.add(:forwarding_rules, "rule #{index + 1} contains an invalid target address")
    end
  end

  def rule_matches_message?(rule, message)
    sender_match = rule["from_address_pattern"].blank? || message.from_address.to_s.downcase.include?(rule["from_address_pattern"])
    subject_match = rule["subject_pattern"].blank? || message.subject.to_s.downcase.include?(rule["subject_pattern"])
    subaddress_match = rule["subaddress_pattern"].blank? || message.subaddress.to_s.downcase.include?(rule["subaddress_pattern"])

    sender_match && subject_match && subaddress_match
  end

  def normalize_forwarding_address(address)
    normalized = address.to_s.strip.downcase
    normalized.presence
  end

  def coerce_json_attributes
    coerce_json_attribute(:pipeline_overrides, expected: Hash, message: "must be valid JSON")
    coerce_json_attribute(:forwarding_rules, expected: Array, message: "must be valid JSON")
  end

  def coerce_json_attribute(attribute_name, expected:, message:)
    value = self[attribute_name]
    return unless value.is_a?(String)

    stripped = value.strip
    self[attribute_name] = (expected == Hash) ? {} : [] and return if stripped.empty?

    parsed = JSON.parse(stripped)
    self[attribute_name] = parsed
  rescue JSON::ParserError
    errors.add(attribute_name, message)
  end

  def drive_folder_belongs_to_domain_user
    return if drive_folder.blank? || drive_folder.user_id == domain&.user_id

    errors.add(:drive_folder_id, "must belong to the domain owner")
  end
end
