module Contacts
  class Backfill
    Result = Data.define(:inbound_messages, :outbound_messages, :contacts)

    def self.call(user: nil)
      new(user: user).call
    end

    def initialize(user: nil)
      @user = user
    end

    def call
      before_contact_count = contacts_scope.count
      inbound_count = backfill_inbound_messages
      outbound_count = backfill_outbound_messages

      Result.new(
        inbound_messages: inbound_count,
        outbound_messages: outbound_count,
        contacts: contacts_scope.count - before_contact_count
      )
    end

    private

    attr_reader :user

    def backfill_inbound_messages
      count = 0

      inbound_scope.find_each do |message|
        Contacts::CommunicationRecorder.record_inbound!(message)
        count += 1
      end

      count
    end

    def backfill_outbound_messages
      count = 0

      outbound_scope.find_each do |outbound_message|
        Contacts::CommunicationRecorder.record_outbound!(outbound_message)
        count += 1
      end

      count
    end

    def inbound_scope
      scope = Message.includes(inbox: :domain).where(contact_id: nil)
      return scope if user.blank?

      scope.joins(inbox: :domain).where(domains: {user_id: user.id})
    end

    def outbound_scope
      scope = OutboundMessage.sent.includes(:domain, :user)
      return scope if user.blank?

      scope.where("outbound_messages.user_id = :user_id OR domains.user_id = :user_id", user_id: user.id).joins(:domain)
    end

    def contacts_scope
      user.present? ? user.contacts : Contact.all
    end
  end
end
