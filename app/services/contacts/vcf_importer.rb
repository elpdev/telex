class Contacts::VcfImporter
  EMAIL_PROPERTIES = %w[EMAIL].freeze
  PHONE_PROPERTIES = %w[TEL].freeze
  WEBSITE_PROPERTIES = %w[URL].freeze
  DIRECT_METADATA_PROPERTIES = %w[ADR BDAY CATEGORIES IMPP KIND NICKNAME NOTE ORG PHOTO REV ROLE SOCIALPROFILE TITLE X-SOCIALPROFILE].freeze

  def self.call(user:, file:)
    new(user:, file:).call
  end

  def initialize(user:, file:)
    @user = user
    @file = file
  end

  def call
    created = 0
    updated = 0
    skipped = 0
    failed = 0
    errors = []

    parse_cards(@file.read).each_with_index do |card, index|
      importable = importable_attributes(card)
      if empty_card?(importable)
        skipped += 1
        next
      end

      Contact.transaction do
        contact = find_contact(importable) || @user.contacts.new(contact_type: :person)
        created += 1 if contact.new_record?
        updated += 1 unless contact.new_record?

        contact.assign_attributes(importable[:contact_attributes].compact_blank)
        contact.metadata = merged_metadata(contact.metadata, importable[:metadata])
        contact.save!
        sync_email_addresses!(contact, importable[:email_addresses])
      end
    rescue => error
      failed += 1
      errors << "vCard #{index + 1}: #{error.message}"
    end

    Contacts::ImportResult.new(created:, updated:, skipped:, failed:, errors:)
  rescue => error
    Contacts::ImportResult.new(created: 0, updated: 0, skipped: 0, failed: 1, errors: [error.message])
  end

  private

  def parse_cards(content)
    cards = []
    current = nil

    unfold_lines(content.to_s).each do |line|
      name, params, value = parse_line(line)
      next if name.blank?

      if name == "BEGIN" && value.casecmp("VCARD").zero?
        current = []
      elsif name == "END" && value.casecmp("VCARD").zero?
        cards << current if current.present?
        current = nil
      elsif current
        current << {name:, params:, value: unescape_value(value)}
      end
    end

    cards
  end

  def unfold_lines(content)
    content.each_line(chomp: true).each_with_object([]) do |line, lines|
      line = line.delete_suffix("\r")
      if line.start_with?(" ", "\t") && lines.any?
        lines[-1] += line[1..]
      else
        lines << line
      end
    end
  end

  def parse_line(line)
    left, value = line.split(":", 2)
    return [nil, {}, nil] if value.nil?

    segments = left.split(";")
    name = segments.shift.to_s.upcase
    params = segments.each_with_object({}) do |segment, hash|
      key, param_value = segment.split("=", 2)
      if param_value.present?
        hash[key.upcase] = param_value.split(",").map(&:strip)
      else
        hash["TYPE"] ||= []
        hash["TYPE"] << key.strip
      end
    end

    [name, params, value.to_s]
  end

  def unescape_value(value)
    value.to_s
      .gsub(/\\[nN]/, "\n")
      .gsub("\\,", ",")
      .gsub("\\;", ";")
      .gsub("\\\\", "\\")
      .strip
  end

  def importable_attributes(card)
    fields = grouped_fields(card)
    phones = values_for(fields, PHONE_PROPERTIES)
    websites = values_for(fields, WEBSITE_PROPERTIES)
    email_addresses = values_for(fields, EMAIL_PROPERTIES).filter_map { |value| ContactEmailAddress.normalize_email(value) }.select { |email| email.match?(URI::MailTo::EMAIL_REGEXP) }.uniq
    name = first_value(fields, "FN").presence || composed_name(first_value(fields, "N"))

    {
      contact_attributes: {
        name: name,
        company_name: first_semicolon_value(first_value(fields, "ORG")),
        title: first_value(fields, "TITLE"),
        phone: phones.first,
        website: websites.first
      },
      email_addresses: email_addresses,
      phone_match: normalize_phone(phones.first),
      metadata: vcard_metadata(fields, phones, websites, email_addresses)
    }
  end

  def grouped_fields(card)
    card.each_with_object({}) do |field, hash|
      next if field[:value].blank?

      hash[field[:name]] ||= []
      hash[field[:name]] << {value: field[:value], params: field[:params]}
    end
  end

  def values_for(fields, names)
    names.flat_map { |name| fields.fetch(name, []) }.map { |field| field[:value].presence }.compact.uniq
  end

  def first_value(fields, name)
    fields.fetch(name, []).first&.fetch(:value)
  end

  def first_semicolon_value(value)
    value.to_s.split(";").find(&:present?)&.strip
  end

  def composed_name(value)
    parts = value.to_s.split(";")
    [parts[1], parts[2], parts[0]].compact_blank.join(" ").presence
  end

  def vcard_metadata(fields, phones, websites, email_addresses)
    vcard = {}
    vcard["phones"] = phones if phones.any?
    vcard["websites"] = websites if websites.any?
    vcard["email_addresses"] = email_addresses if email_addresses.any?

    fields.each do |name, entries|
      next if %w[BEGIN END VERSION FN N EMAIL TEL URL].include?(name)
      next unless DIRECT_METADATA_PROPERTIES.include?(name) || name.start_with?("X-")

      values = entries.map { |entry| entry[:value].presence }.compact
      vcard[name.downcase] = values.one? ? values.first : values if values.any?
    end

    vcard
  end

  def empty_card?(importable)
    importable[:contact_attributes].values.all?(&:blank?) && importable[:email_addresses].blank? && importable[:metadata].blank?
  end

  def find_contact(importable)
    contact_for_email(importable[:email_addresses]) || contact_for_phone(importable[:phone_match])
  end

  def contact_for_email(email_addresses)
    return if email_addresses.blank?

    ContactEmailAddress.includes(:contact).where(user: @user, email_address: email_addresses).first&.contact
  end

  def contact_for_phone(phone_match)
    return if phone_match.blank?

    @user.contacts.find { |contact| normalize_phone(contact.phone) == phone_match }
  end

  def normalize_phone(value)
    digits = value.to_s.gsub(/\D/, "")
    return if digits.blank?

    (digits.length >= 10) ? digits.last(10) : digits
  end

  def merged_metadata(existing, imported)
    metadata = existing.is_a?(Hash) ? existing.deep_dup : {}
    metadata["vcard"] = metadata.fetch("vcard", {}).merge(imported) if imported.any?
    metadata
  end

  def sync_email_addresses!(contact, email_addresses)
    email_addresses.each_with_index do |email_address, index|
      email = ContactEmailAddress.find_or_initialize_by(user: @user, email_address: email_address)
      email.contact = contact
      email.label ||= "email"
      email.primary_address = true if index.zero? && !contact.email_addresses.where(primary_address: true).where.not(id: email.id).exists?
      email.save!
    end
  end
end
