module Inbound
  class PipelineContext
    attr_reader :inbound_email, :inbox, :message, :subaddress
    attr_accessor :metadata

    def initialize(inbound_email:, inbox:, message:, subaddress:, metadata: nil)
      @inbound_email = inbound_email
      @inbox = inbox
      @message = message
      @subaddress = subaddress
      @metadata = (metadata || message.metadata).deep_dup
      @halted = false
    end

    def halt!
      @halted = true
    end

    def halted?
      @halted
    end
  end
end
