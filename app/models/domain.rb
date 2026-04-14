class Domain < ApplicationRecord
  SMTP_AUTHENTICATION_METHODS = %w[plain login cram_md5].freeze

  belongs_to :user
  has_many :inboxes, dependent: :destroy, inverse_of: :domain
  has_many :outbound_messages, dependent: :destroy, inverse_of: :domain
  has_many :email_signatures, dependent: :destroy, inverse_of: :domain
  has_many :email_templates, dependent: :destroy, inverse_of: :domain

  encrypts :smtp_username, :smtp_password

  normalizes :name, with: ->(value) { value.to_s.strip.downcase }
  normalizes :outbound_from_address, :reply_to_address, with: ->(value) { value.to_s.strip.downcase }
  normalizes :smtp_host, :smtp_authentication, with: ->(value) { value.to_s.strip.downcase }
  normalizes :outbound_from_name, with: ->(value) { value.to_s.squish }

  validates :name, presence: true, uniqueness: true
  validates :smtp_port, numericality: {only_integer: true, greater_than: 0}, allow_nil: true
  validates :smtp_authentication, inclusion: {in: SMTP_AUTHENTICATION_METHODS}, allow_blank: true

  validate :validate_outbound_configuration

  def outbound_configured?
    [
      outbound_from_name,
      outbound_from_address,
      reply_to_address,
      smtp_host,
      smtp_port,
      smtp_username,
      smtp_password,
      smtp_authentication
    ].any?(&:present?) || !use_from_address_for_reply_to?
  end

  def outbound_ready?
    active? && outbound_configured? && outbound_configuration_errors.empty?
  end

  def outbound_identity
    return unless outbound_ready?

    {
      from: formatted_outbound_from,
      from_name: outbound_from_name,
      from_address: outbound_from_address,
      reply_to: resolved_reply_to_address
    }
  end

  def smtp_delivery_settings
    return unless outbound_ready?

    {
      address: smtp_host,
      port: smtp_port,
      user_name: smtp_username,
      password: smtp_password,
      authentication: smtp_authentication.to_sym,
      enable_starttls_auto: smtp_enable_starttls_auto
    }
  end

  def outbound_configuration_errors
    errors = []

    errors << "domain must be active" unless active?
    errors << "outbound_from_name can't be blank" if outbound_from_name.blank?
    errors << "outbound_from_address can't be blank" if outbound_from_address.blank?
    errors << "smtp_host can't be blank" if smtp_host.blank?
    errors << "smtp_port can't be blank" if smtp_port.blank?
    errors << "smtp_username can't be blank" if smtp_username.blank?
    errors << "smtp_password can't be blank" if smtp_password.blank?
    errors << "smtp_authentication can't be blank" if smtp_authentication.blank?

    if outbound_from_address.present? && !valid_email_address?(outbound_from_address)
      errors << "outbound_from_address is invalid"
    end

    if !use_from_address_for_reply_to? && reply_to_address.blank?
      errors << "reply_to_address can't be blank"
    end

    if reply_to_address.present? && !valid_email_address?(reply_to_address)
      errors << "reply_to_address is invalid"
    end

    if smtp_port.present? && smtp_port.to_i <= 0
      errors << "smtp_port must be greater than 0"
    end

    if smtp_authentication.present? && !SMTP_AUTHENTICATION_METHODS.include?(smtp_authentication)
      errors << "smtp_authentication is not included in the list"
    end

    errors
  end

  def formatted_outbound_from
    address = Mail::Address.new(outbound_from_address)
    address.display_name = outbound_from_name
    address.format
  end

  def resolved_reply_to_address
    use_from_address_for_reply_to? ? outbound_from_address : reply_to_address
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[active created_at id name outbound_from_address outbound_from_name reply_to_address smtp_authentication smtp_host smtp_port updated_at use_from_address_for_reply_to user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[inboxes outbound_messages user]
  end

  private

  def validate_outbound_configuration
    return unless outbound_configured?

    errors.add(:outbound_from_name, "can't be blank") if outbound_from_name.blank?
    errors.add(:outbound_from_address, "can't be blank") if outbound_from_address.blank?
    errors.add(:outbound_from_address, "is invalid") if outbound_from_address.present? && !valid_email_address?(outbound_from_address)
    errors.add(:reply_to_address, "can't be blank") if !use_from_address_for_reply_to? && reply_to_address.blank?
    errors.add(:reply_to_address, "is invalid") if reply_to_address.present? && !valid_email_address?(reply_to_address)
    errors.add(:smtp_host, "can't be blank") if smtp_host.blank?
    errors.add(:smtp_port, "can't be blank") if smtp_port.blank?
    errors.add(:smtp_username, "can't be blank") if smtp_username.blank?
    errors.add(:smtp_password, "can't be blank") if smtp_password.blank?
    errors.add(:smtp_authentication, "can't be blank") if smtp_authentication.blank?
  end

  def valid_email_address?(value)
    value.match?(URI::MailTo::EMAIL_REGEXP)
  end
end
