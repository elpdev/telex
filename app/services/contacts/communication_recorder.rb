module Contacts
  class CommunicationRecorder
    def self.record_inbound!(message)
      new.record_inbound!(message)
    end

    def self.record_outbound!(outbound_message)
      new.record_outbound!(outbound_message)
    end

    def record_inbound!(message)
      contact = message.contact || Contact.find_or_create_for_email!(
        user: message.inbox.domain.user,
        email_address: message.from_address,
        name: message.from_name
      )
      return if contact.blank?

      message.update!(contact: contact) if message.contact_id != contact.id
      create_communication!(contact, message, occurred_at: message.occurred_at, metadata: {"direction" => "inbound"})
    end

    def record_outbound!(outbound_message)
      user = outbound_message.user || outbound_message.domain.user

      outbound_message.participant_addresses.excluding(outbound_message.from_address.to_s.downcase).each do |email_address|
        contact = Contact.find_or_create_for_email!(user: user, email_address: email_address)
        next if contact.blank?

        create_communication!(contact, outbound_message, occurred_at: outbound_message.occurred_at, metadata: {"direction" => "outbound"})
      end
    end

    private

    def create_communication!(contact, communicable, occurred_at:, metadata: {})
      ContactCommunication.find_or_create_by!(contact: contact, communicable: communicable) do |communication|
        communication.user = contact.user
        communication.occurred_at = occurred_at || Time.current
        communication.metadata = metadata
      end
    end
  end
end
