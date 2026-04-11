module Outbound
  class SignatureInjector
    SPACER = "<div><br></div><div><br></div>".freeze

    def self.call(domain:, existing: "")
      new(domain: domain, existing: existing).call
    end

    def initialize(domain:, existing: "")
      @domain = domain
      @existing = existing.to_s
    end

    def call
      signature = EmailSignature.default_for(domain).first
      return existing unless signature

      SPACER + signature.body.to_s + existing
    end

    private

    attr_reader :domain, :existing
  end
end
